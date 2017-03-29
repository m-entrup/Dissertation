import pandas as pd
import numpy as np
from sklearn.metrics import r2_score
import os
import re

def _add_parameters(dataset, parameters):
    parameters = parameters.split(',')
    dataset['Threshold'] = pd.Series([parameters[0]] * len (dataset), index=dataset.index)
    dataset['Step_Size'] = pd.Series([int(parameters[1])] * len (dataset), index=dataset.index)
    dataset['Left_Offset'] = pd.Series([int(parameters[2])] * len (dataset), index=dataset.index)
    dataset['Right_Offset'] = pd.Series([int(parameters[3])] * len (dataset), index=dataset.index)
    dataset['Polynomial_Order'] = pd.Series([int(parameters[4].replace('poly', ''))] * len (dataset), index=dataset.index)
    return dataset

def _load_dataset(directory, sm, qsink7, comment, parameters):
    dataframes = []
    count = 0
    for file in os.listdir(directory):
        if file.endswith('.csv'):
            count += 1
            csv_data = pd.read_csv(os.path.join(directory, file), sep=';')
            csv_data['File'] = pd.Series([count] * len(csv_data), index=csv_data.index)
            dataframes.append(csv_data)
    dataframe = pd.concat(dataframes, ignore_index=True)
    dataframe['SpecMag'] = pd.Series([float(sm)] * len (dataframe), index=dataframe.index)
    dataframe['QSinK7'] = pd.Series([float(qsink7)] * len (dataframe), index=dataframe.index)
    dataframe['Comment'] = pd.Series([comment] * len (dataframe), index=dataframe.index)
    dataframe['File_Count'] = pd.Series([count] * len (dataframe), index=dataframe.index)
    dataframe = _add_parameters(dataframe, parameters)
    return dataframe

def load_dataframe(path='/run/media/michael/LinuxSSD/SR-EELS Daten/'):
    '''Load all data set from a SR-EELS characterization databas as a pandas DataFrame.
    Returns the newly created DataFrame.
    :param path: A string that represents the path to the database (optional).
    '''
    if not os.path.exists(path):
        raise FileNotFoundError('Can\'t find %s' % (path,))
    dataframes = []
    # 1st group: SpecMag
    # 2nd group: QSinK7
    # 3rd group: Name of the calibration data set
    # 4th group: Parameters of the characterization (Thresholding, step size, lower offser, upper offset, fit)
    database_pattern = 'SM(\d+(?:\.\d+)?)[/\\\\](-?\d+(?:\.\d+)?)[/\\\\](.*)[/\\\\](.*)$'
    for root, _, files in os.walk(path):
        match = re.search(database_pattern, root)
        if match:
            sm = float(match.group(1))
            qsink7 = float(match.group(2))
            comment = match.group(3)
            parameters = match.group(4)
            dataframes.append(_load_dataset(root, sm, qsink7, comment, parameters))
    dataset = pd.concat(dataframes, ignore_index=True)
    dataset.sort_values(by=['SpecMag', 'QSinK7', 'Comment', 'File'])
    return dataset