interface Window {
  ethereum?: {
    request: (args: { method: string; params?: any[] }) => Promise<any>;
    on: (event: string, handler: (accounts: string[]) => void) => void;
    removeListener: (
      event: string,
      handler: (accounts: string[]) => void
    ) => void;
  };
}
