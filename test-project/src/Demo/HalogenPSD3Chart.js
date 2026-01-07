// FFI for HalogenPSD3Chart - JSON message parsing
export const parseDataMessageImpl = msg => {
  try {
    const data = JSON.parse(msg);
    if (data.type === "data" && data.values) {
      return {
        tick: data.tick,
        time: data.time,
        primary: data.values.primary,
        secondary: data.values.secondary
      };
    }
    return null;
  } catch (e) {
    return null;
  }
};
