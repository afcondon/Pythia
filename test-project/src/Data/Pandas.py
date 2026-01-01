# Pandas FFI implementation for PurePy
# Requires: pip install pandas

import pandas as pd
import numpy as np

def readCsvImpl(path):
    def effect():
        return pd.read_csv(path)
    return effect

def toRecords(df):
    """Convert DataFrame to list of dicts (PureScript records)."""
    return df.to_dict(orient='records')

def describe(df):
    def effect():
        return df.describe().to_string()
    return effect

def headImpl(df, n):
    return df.head(n)

def shape(df):
    rows, cols = df.shape
    return {"rows": rows, "cols": cols}

def columns(df):
    return list(df.columns)

def selectColumnsImpl(df, cols):
    return df[cols]

def filterRowsImpl(df, condition):
    return df.query(condition)

def groupByImpl(df, cols):
    return df.groupby(cols)

def mean(df):
    def effect():
        result = df.mean(numeric_only=True)
        return result.to_dict()
    return effect

def sum(df):
    def effect():
        result = df.sum(numeric_only=True)
        return result.to_dict()
    return effect

def count(df):
    return len(df)

def fromRecordsImpl(records):
    return pd.DataFrame(records)

# Additional utility functions for data processing

def computeStats(df, column):
    """Compute statistics for a column, returns PureScript Stats record."""
    series = df[column]
    return {
        "mean": float(series.mean()),
        "median": float(series.median()),
        "stdDev": float(series.std()),
        "min": float(series.min()),
        "max": float(series.max()),
        "count": int(len(series))
    }

def toDataPoints(df, x_col, y_col, label_col=None):
    """Convert DataFrame to array of DataPoint records for visualization."""
    points = []
    for _, row in df.iterrows():
        point = {
            "x": float(row[x_col]),
            "y": float(row[y_col]),
            "label": str(row[label_col]) if label_col else ""
        }
        points.append(point)
    return points

def toTimeSeries(df, time_col, value_col, series_col=None):
    """Convert DataFrame to array of TimeSeriesPoint records."""
    points = []
    for _, row in df.iterrows():
        point = {
            "timestamp": str(row[time_col]),
            "value": float(row[value_col]),
            "series": str(row[series_col]) if series_col else "default"
        }
        points.append(point)
    return points

def generateSampleData(n=100):
    """Generate sample data for testing."""
    np.random.seed(42)
    x = np.linspace(0, 10, n)
    y = np.sin(x) + np.random.normal(0, 0.1, n)
    return pd.DataFrame({
        'x': x,
        'y': y,
        'label': [f'point_{i}' for i in range(n)]
    })
