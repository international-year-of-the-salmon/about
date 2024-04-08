import pandas as pd


def define_env(env):
    @env.macro
    def csv_to_table(file_path):
        df = pd.read_csv(file_path)
        return df.to_html(index=False)


def define_env(env):
    @env.macro
    def sum_citations(file_path):
        df = pd.read_csv(file_path)
        sum_citations = df["citations"].sum()
        date = pd.to_datetime("today").strftime("%B %dth, %Y")
        return f"There has been {sum_citations} Citations of IYS data as of {date}. Click here to see the 10 most cited."
