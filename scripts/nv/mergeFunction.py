import csv
import os

def MergeCsvFiles(output_file='cities.csv', folder_path='cities/'):
    # load data from csv file
    # reader = csv.reader(open(input_file, 'rb'))
    writer = csv.writer(open(output_file, 'a'), delimiter=',', lineterminator='\n')

    # get file list
    dirs = os.listdir(folder_path)

    # merge files
    file_counter = 0
    for file in dirs:
        reader = csv.reader(open(folder_path + file, 'rb'))
        line_counter = 0
        for row in reader:
            if line_counter != 0 or file_counter == 0:
                writer.writerow(row)
            line_counter += 1
        file_counter += 1

# MergeCsvFiles()
