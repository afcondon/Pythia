// FFI stub for PureScript compiler - actual implementation is in Pandas.py
export const readCsvImpl = path => () => { throw new Error("Python FFI only"); };
export const toRecords = df => [];
export const describe = df => () => "";
export const headImpl = (df, n) => df;
export const shape = df => ({ rows: 0, cols: 0 });
export const columns = df => [];
export const selectColumnsImpl = (df, cols) => df;
export const filterRowsImpl = (df, condition) => df;
export const groupByImpl = (df, cols) => df;
export const mean = df => () => ({});
export const sum = df => () => ({});
export const count = df => 0;
export const fromRecordsImpl = records => ({});
