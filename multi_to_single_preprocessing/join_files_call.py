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

    #Clean
    combined_df.iloc[:, 3] = combined_df.iloc[:, 3].apply(modify_phone_number)
    combined_df.iloc[:, 4] = combined_df.iloc[:, 4].apply(modify_phone_number)

    #Remark Names
    # combined_df.iloc[:, 4] = combined_df.groupby(combined_df.iloc[:, 3])[combined_df.columns[4]].transform(
    #     lambda x: ' '.join(sorted(set(x)))  # Convert to set to remove duplicates, then join
    # )
    
    combined_df.to_csv(output_file, index=False)


def modify_phone_number(pn):
    phone_number = str(pn)
    if len(phone_number) == 12 and phone_number.startswith('+1') and phone_number[2:].isdigit():
        return phone_number[2:]  # Keep the last 10 digits
    elif len(phone_number) == 11 and phone_number.startswith('1') and phone_number[1:].isdigit():
        return phone_number[1:]  # Keep the last 10 digits
    else:
        return phone_number  # Leave unchanged if it doesn't match the conditions



parser = argparse.ArgumentParser()

parser.add_argument("--input", type=str, required=True)
parser.add_argument("--output", type=str, required=True)

args = parser.parse_args()

combine_files(args.input, args.output)