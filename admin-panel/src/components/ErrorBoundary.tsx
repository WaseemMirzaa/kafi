import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}
interface State {
  error: Error | null;
}

/**
 * Catches render exceptions so a single malformed record (e.g. a bad nanny doc
 * with a wrong-typed field) can't white-screen the entire admin panel. Shows a
 * recoverable fallback instead of an unmounted blank page.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // eslint-disable-next-line no-console
    console.error('Admin panel render error:', error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 24, fontFamily: 'system-ui, sans-serif', color: '#1A2B4A' }}>
          <h2 style={{ fontSize: 16, fontWeight: 800, margin: 0 }}>Something went wrong</h2>
          <p style={{ fontSize: 12, color: '#8090B0', marginTop: 6 }}>
            {this.state.error.message || 'An unexpected error occurred while rendering this page.'}
          </p>
          <div style={{ marginTop: 12, display: 'flex', gap: 12, fontSize: 12 }}>
            <button type="button" onClick={() => this.setState({ error: null })}>
              Try again
            </button>
            <a href="/">Go to dashboard</a>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}
