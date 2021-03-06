import matplotlib as mpl; mpl.use('TkAgg')
import matplotlib.pyplot as plt
import os
import pandas as pd

from easyml.random_forest import easy_random_forest
from easyml.preprocess import preprocess_scaler


# Set matplotlib settings
plt.style.use('ggplot')
os.chdir('./Python/examples/cocaine_dependence/random_forest')

if __name__ == "__main__":
    # Load data
    cocaine_dependence = pd.read_table('./cocaine_dependence.txt')

    # Analyze data
    easy_random_forest(cocaine_dependence, 'DIAGNOSIS',
                       family='binomial', exclude_variables=['subject'], categorical_variables=['Male'],
                       random_state=1, progress_bar=True, n_core=1,
                       n_samples=100, n_divisions=10, n_iterations=5)

    # Analyze data
    easy_random_forest(cocaine_dependence, 'DIAGNOSIS', preprocessor=preprocess_scaler,
                       family='binomial', exclude_variables=['subject'], categorical_variables=['Male'],
                       random_state=1, progress_bar=True, n_core=1,
                       n_samples=100, n_divisions=10, n_iterations=5)

    # Analyze data
    easy_random_forest(cocaine_dependence, 'DIAGNOSIS',
                       family='binomial', exclude_variables=['subject'], categorical_variables=['Male'],
                       random_state=1, progress_bar=True, n_core=os.cpu_count(),
                       n_samples=100, n_divisions=10, n_iterations=5)
