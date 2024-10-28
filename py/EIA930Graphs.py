import pandas as pd
import networkx as nx

class EIA930Year(nx.MultiDiGraph):
    """
    An nx.MultiDiGraph subclass for storing and manipulating a year's worth of EIA930
    INTERCHANGE and BALANCE data from pandas dataframes. Each node has a 
    'balance_data' attribute keyed off 'Unix_Timestamp', and each INTERCHANGE row is
    treated as a separate edge also keyed off of 'Unix_Timestamp'.

    Parameters
    ----------
    interchange_df : a pandas dataframe with yearly EIA930 interchange data
    balance_df : a pandas dataframe with yearly EIA930 balance data

    Examples
    --------
    >>> G = EIA930Year(interchange_df, balance_df)
    >>> G['AECI']['MISO'][1672556400]
    {'Interchange_MW': 431.0, 'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}
    >>> G.nodes['AECI']['balance_data'][1672556400]
    {'Demand_Forecast_MW': 2467.0,
     'Demand_MW': 2495.0,
     'Net_Generation_MW': 2698.0,
     'Total_Interchange_MW': 203.0,
     'SumValid_DIBAs_MW': 203.0,
     'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}
    """

    def __init__(self, interchange_df, balance_df):
        """
        Initialize a nx.MultiDiGraph with yearly EIA930 interchange and balance data

        Parameters
        ----------
        interchange_df : a pandas dataframe with yearly EIA930 interchange data
        balance_df : a pandas dataframe with yearly EIA930 balance data
        """
        super().__init__()

        self._interchange_df = interchange_df
        self._balance_df = balance_df

        self._add_time_cols_to_dfs()

        self._initialize_from_interchange_df()
        self._initialize_from_balance_df()

    def _add_time_cols_to_dfs(self):
        """
        Add ISO8601 and Unix_Timestamp columns to interchange and balance dfs
        """

        self._interchange_df['ISO8601_UTC_End'] = (
            pd.to_datetime(self._interchange_df['UTC_Time_at_End_of_Hour']))
        self._interchange_df['Unix_Timestamp'] = (
            self._interchange_df['ISO8601_UTC_End'].apply(lambda x: int(x.timestamp())))

        self._balance_df['ISO8601_UTC_End'] = (
            pd.to_datetime(self._balance_df['UTC_Time_at_End_of_Hour']))
        self._balance_df['Unix_Timestamp'] = (
            self._balance_df['ISO8601_UTC_End'].apply(lambda x: int(x.timestamp())))

    def _initialize_from_interchange_df(self):
        """
        Initialize the graph from the interchange dataframe
        Each timestamp interchange is one edge in the MultiDiGraph
        """
        nx.from_pandas_edgelist(
            self._interchange_df,
            source='Balancing_Authority',
            target='Directly_Interconnected_Balancing_Authority',
            edge_attr=['Interchange_MW', 'ISO8601_UTC_End'],
            edge_key='Unix_Timestamp',
            create_using=self
        )

    def _initialize_from_balance_df(self):
        """
        Initialize the BA generation data from balance dataframe
        """
        for _, row in self._balance_df.iterrows():
            # TODO: include all generation data
            ba = row['Balancing_Authority']
            timestamp = row['Unix_Timestamp']
            region = row['Region']
        
            node_data = {
                timestamp: {
                    'Demand_Forecast_MW': row['Demand_Forecast_MW'],
                    'Demand_MW': row['Demand_MW'],
                    'Net_Generation_MW': row['Net_Generation_MW'],
                    'Total_Interchange_MW': row['Total_Interchange_MW'],
                    'SumValid_DIBAs_MW': row['SumValid_DIBAs_MW'],
                    'ISO8601_UTC_End': row['ISO8601_UTC_End']
                }
            }
        
            if 'region' not in self.nodes[ba]:
                self.nodes[ba]['region'] = region
        
            # Update or initialize the node attribute to store time-series data
            if 'balance_data' in self.nodes[ba]:
                self.nodes[ba]['balance_data'].update(node_data)
            else:
                self.nodes[ba]['balance_data'] = node_data

class EIA930Hour(nx.DiGraph):
    """
    An nx.DiGraph subclass for storing and manipulating one hour's worth of
    EIA930 INTERCHANGE and BALANCE data, initialized from and EIA930year object

    Parameters
    ----------
    incoming_yearly_graph : an EIA930year MultiDiGraph object with one year's data
    timestamp : an integer Unix Timestamp
    """

class EIA930Grid(nx.Graph):
    """
    An nx.Graph subclass for inferring the simple graph structure of the
    electrical grid from an EIA930Year or EIA930Hour object.
    That is, this class strips all generation, interchange_mw, and timestamp
    attributes and is just a simple graph with an edge between BAs
    if there is an interconnection. Useful for investigating overall
    grid graph properties.
    
    Parameters
    ----------
    incoming_EIA_graph : an EIA930Year or EIA930Hour graph object
    """
