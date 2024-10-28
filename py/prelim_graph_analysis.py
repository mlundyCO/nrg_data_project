import EIA930Graphs as eg
import sys
import pandas as pd
import matplotlib.pyplot as plt
import networkx as nx
from pathlib import Path
from IPython import embed

def assign_paths_filenames():
    # Assigns paths and filenames for later use
    if len(sys.argv) < 2:
        print("Usage: python script_name.py <year>")
        sys.exit(1)
    
    # Assumes script is in nrg_data_project/py/
    year = sys.argv[1]
    project_root = Path(__file__).resolve().parents[1]
    interchange_filename = "EIA930_INTERCHANGE_" + year + "_Jan_Jun.csv.clean"
    balance_filename = "EIA930_BALANCE_" + year + "_Jan_Jun.csv.clean"
    interchange_filepath = project_root / "data" / interchange_filename
    balance_filepath = project_root / "data" / balance_filename
    return {"project_root": project_root,
            "interchange_filename": interchange_filename,
            "balance_filename": balance_filename,
            "interchange_filepath": interchange_filepath,
            "balance_filepath": balance_filepath}

files = assign_paths_filenames()

# Construct an EIA930Grid object for overall grid analysis
    # TODO: Stitch two 6-month files together
interchange_df = pd.read_csv(files["interchange_filepath"])
balance_df = pd.read_csv(files["balance_filepath"])
# Uses custom EIA930Graphs classes
G = eg.EIA930Year(interchange_df, balance_df)
simple_G = eg.EIA930Grid(G)

def find_max_deg_nodes(degreeView):
    # Find the nodes of maximum degree
    max_deg = max(d for _,d in degreeView)
    max_nodes = []
    for node,d in degreeView:
        if d == max_deg:
            max_nodes.append(node)
    print('The maximum degree is:', max_deg)
    print('The nodes with maximum degree are:', max_nodes)

def save_deg_hist(degreeView):
    degdf = pd.DataFrame.from_dict(DV)
    bins = [x+0.5 for x in range(0,19)]
    degdf[1].plot.hist(bins=bins, rwidth=0.9)
    plt.xticks(range(1,19))
    plt.xlabel('Node Degree')
    plt.title('Histogram of interchange network node degrees')
    deg_hist_path = files["project_root"] / 'fig' / 'degree_histogram.png'
    plt.savefig(deg_hist_path)
    print("Degree histogram saved to", deg_hist_path)

def find_bad_cut_edges(Graph, degreeView):
    # Find cut-edges incident to nodes with degree greater than 1
    is_bad_cut_edge = False
    for e in nx.bridges(Graph):
        if degreeView(e[0]) != 1 and degreeView(e[1]) != 1:
            is_bad_cut_edge = True
            print('A non-trivial cut edge exists:', e)
    if not is_bad_cut_edge:
        print('The only cut-edges connect nodes of degree 1.')

DV = simple_G.degree
find_max_deg_nodes(DV)
save_deg_hist(DV)
find_bad_cut_edges(simple_G, DV)

def find_cliques(Graph):
    # Find the clique number and print the maximum cliques
    cliques = list(nx.enumerate_all_cliques(Graph))
    clique_num = max(len(c) for c in cliques)
    print("The clique number is: ", clique_num)
    for c in cliques:
        if len(c) == clique_num:
            print(c, " is a maximum clique.")

find_cliques(simple_G)

# TODO: look into pricing data https://www.eia.gov/electricity/wholesalemarkets/
# TODO: find the most altruistic BA
# TODO: reproduce R time series results by creating subgraphs on timestamps and summing edge weights
# TODO: look for directed loops within an hour's data, because that would be odd
# TODO: consider if NO interchange, removing the edge? Depends what algorithm we want to run
