import pandas as pd
import matplotlib.pyplot as plt

def analyze_request_log(csv_file_path):
    # Read the CSV file
    df = pd.read_csv(csv_file_path)
    
    # Convert timestamp to datetime
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    
    # Group by client_ip and path, count occurrences
    path_counts = df.groupby(['client_ip', 'path']).size().unstack(fill_value=0)
    
    # Plot the results
    path_counts.plot(kind='bar', stacked=True, figsize=(12, 6))
    plt.title('Request Counts by Client IP and Path')
    plt.xlabel('Client IP')
    plt.ylabel('Request Count')
    plt.legend(title='Path', bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    plt.show()

# Usage
analyze_request_log('logs/request_log_2023-05-15.csv')