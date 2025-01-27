import os, argparse
import pandas as pd

def split_multi(file_path, output_folder):


    df = pd.read_csv(file_path)

    grouped = df.groupby(df.columns[3])

    os.makedirs(output_folder, exist_ok=True)

    for group_value, group_df in grouped:

        if len(group_value) > 15 or group_value.startswith("discord"):
            print("PASSING")
            continue
        
        output_file = os.path.join(output_folder, f"{group_value.replace('*', '_')}.csv")
        
        group_df.to_csv(output_file, index=False)


parser = argparse.ArgumentParser()

parser.add_argument("--input", type=str, required=True)
parser.add_argument("--output", type=str, required=False)

args = parser.parse_args()

split_multi(args.input, args.output)