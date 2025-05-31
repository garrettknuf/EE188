import pandas as pd
import matplotlib.pyplot as plt

# Load the CSV file
file_path = "P120cache.csv"
df = pd.read_csv(file_path, header=0, index_col=0)

def parse_size(size_str):
    size_str = size_str.split() # tokenize
    units = {"B": 1, "KB": 1024, "MB": 1024**2} # find units
    factor = units[size_str[1]]
    return factor * int(size_str[0]) # return number of bytes

if __name__ == "__main__":

    # Convert text sizes to number of bytes
    stride_sizes = [parse_size(size) for size in df.columns]
    
    # Plot figure
    plt.figure(figsize=(14, 8))
    for index, row in df.iterrows():
        plt.plot(stride_sizes, row, label=index)

    # Change plot settings
    plt.xscale("log", base=2)
    plt.xlabel("Stride Size (bytes)")
    plt.ylabel("Time per memory access (nanoseconds)")
    plt.title("Memory Access Time vs. Stride Size for Different Array Sizes")
    plt.xticks(stride_sizes, df.columns, rotation=45)
    plt.legend(title="Array Size", bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.tight_layout()
    plt.show()