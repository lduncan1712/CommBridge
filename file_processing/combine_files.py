import argparse, os
import pandas as pd

def combine_files(input_folder, output_file):

    files = [os.path.join(root, file) for root, dirs, files in os.walk(input_folder) for file in files if file.endswith('.csv')]
    
    # Combine all CSVs into a single DataFrame
    combined_df = pd.concat([pd.read_csv(file) for file in files])

    # Remove duplicate rows
    combined_df = combined_df.drop_duplicates()

    #Sort
    combined_df = combined_df.sort_values(by=combined_df.columns[1], ascending=True)

    # Save the combined data to the output file
    combined_df.to_csv(output_file, index=False)







parser = argparse.ArgumentParser()

parser.add_argument("--input", type=str, required=True)
parser.add_argument("--output", type=str, required=True)

args = parser.parse_args()

combine_files(args.input, args.output)