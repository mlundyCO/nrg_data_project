import networkx as nx
import pandas as pd

class EIA930GraphBuilder:
    """
    Class to aid in building various graphs from EIA930 balance and interchange
    data.

    Parameters
    ----------
    interchange_df : a pandas dataframe holding EIA930 interchange data
    balance_df : a pandas datafram holding EIA930 balance data

    Examples
    --------
    >>> builder = EIA930GraphBuilder(interchange_df, balance_df)
    >>> G = builder.build_multi_digraph
    >>> G['AECI']['MISO'][1672556400]
    {'Interchange_MW': 431.0, 'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}
    >>> G.nodes['AECI']['balance_data'][1672556400]
    {'Demand_Forecast_MW': 2467.0,
     'Demand_MW': 2495.0,
     'Net_Generation_MW': 2698.0,
     'Total_Interchange_MW': 203.0,
     'SumValid_DIBAs_MW': 203.0,
     'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}

    >>> G_hour = builder.build_hour_digraph(1672556400)
    >>> G_hour['AECI']['MISO']
    {'Interchange_MW': 431.0, 'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}
    >>> G_hour['AECI']['balance_data']
    {'Demand_Forecast_MW': 2467.0,
     'Demand_MW': 2495.0,
     'Net_Generation_MW': 2698.0,
     'Total_Interchange_MW': 203.0,
     'SumValid_DIBAs_MW': 203.0,
     'ISO8601_UTC_End': Timestamp('2023-01-01 07:00:00')}
    
    >>> G_grid = builder.build_grid_graph()
    >>> len(G_grid.edges)
    153
    """
    def __init__(self, interchange_df, balance_df):
        self.interchange_df = interchange_df
        self.balance_df = balance_df

        # Build the MultiDiGraph
        self._init_multi_digraph()

    def _init_multi_digraph(self):
        self._add_time_cols_to_dfs()

        self._initialize_from_interchange_df()
        self._initialize_from_balance_df()

    def _add_time_cols_to_dfs(self):
        """
        Add ISO8601 and Unix_Timestamp columns to interchange and balance dfs
        """

        self.interchange_df['ISO8601_UTC_End'] = (
            pd.to_datetime(self.interchange_df['UTC_Time_at_End_of_Hour']))
        self.interchange_df['Unix_Timestamp'] = (
            self.interchange_df['ISO8601_UTC_End'].apply(lambda x: int(x.timestamp())))

        self.balance_df['ISO8601_UTC_End'] = (
            pd.to_datetime(self.balance_df['UTC_Time_at_End_of_Hour']))
        self.balance_df['Unix_Timestamp'] = (
            self.balance_df['ISO8601_UTC_End'].apply(lambda x: int(x.timestamp())))

    def _initialize_from_interchange_df(self):
        """
        Initialize the graph from the interchange dataframe
        Each timestamp interchange is one edge in the MultiDiGraph
        """
        self.G = nx.from_pandas_edgelist(
            self.interchange_df,
            source='Balancing_Authority',
            target='Directly_Interconnected_Balancing_Authority',
            edge_attr=['Interchange_MW', 'ISO8601_UTC_End'],
            edge_key='Unix_Timestamp',
            create_using=nx.MultiDiGraph
        )

    def _initialize_from_balance_df(self):
        """
        Initialize the BA generation data from balance dataframe
        """
        for _, row in self.balance_df.iterrows():
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
        
            if 'region' not in self.G.nodes[ba]:
                self.G.nodes[ba]['region'] = region
        
            # Update or initialize the node attribute to store time-series data
            if 'balance_data' in self.G.nodes[ba]:
                self.G.nodes[ba]['balance_data'].update(node_data)
            else:
                self.G.nodes[ba]['balance_data'] = node_data

    def build_multi_digraph(self):
        # Just return the pre-built multidigraph
        return self.G

    def build_hour_digraph(self, timestamp):
        # Build the digraph for a single timestamp
        self.cur_timestamp = timestamp
        digraph = nx.DiGraph(
                nx.subgraph_view(
                    self.G, filter_edge=self._filter_edge
                )
        )

        # TODO: filter node balance on timestamp as well
        return digraph

    def _filter_edge(self, u, v, key):
        if key == self.cur_timestamp:
            return True

    def build_grid_graph(self):
        # Build the simple graph inferred from timestamped edge data
        return nx.Graph(self.G.edges())
