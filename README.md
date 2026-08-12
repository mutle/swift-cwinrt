# swift-cwinrt

> [!WARNING]
> This project contains an outdated snapshot of a subset of WinRT projections generated with [swift-winrt](https://github.com/thebrowsercompany/swift-winrt), provided for illustration purposes. To use WinRT APIs in your Swift project, we recommend using [swift-winrt](https://github.com/thebrowsercompany/swift-winrt) directly to generate your own projections.

C API definition used by Swift Language bindings.

This project references all metadata files uses by the various swift-* projects. The CWinRT contains the C ABI definitions for all types that can be used.

On Windows, the `CWinRT` module exposes the generated WinRT C API. On other
platforms, the same product and target remain available as an empty module so
cross-platform Swift packages can depend on it without requiring Windows SDK
headers.
