import StoreKit

/// A single bounded catalog request. Cancellation and completion resume its waiter exactly once.
@MainActor final class TiloProductRequest {
    private var continuation: CheckedContinuation<[Product], Error>?
    private var fetchTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    func fetch(ids: [String], timeout: TimeInterval = 20, loader: @escaping ([String]) async throws -> [Product] = { try await Product.products(for: $0) }) async throws -> [Product] {
        try await withCheckedThrowingContinuation { waiter in
            continuation = waiter
            fetchTask = Task { [weak self] in
                do {
                    let products = try await loader(ids)
                    self?.complete(.success(products))
                } catch { self?.complete(.failure(error)) }
            }
            timeoutTask = Task { [weak self] in
                do { try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000)) }
                catch { return }
                self?.complete(.failure(WalletError.catalogTimedOut))
            }
        }
    }

    func cancel() { complete(.failure(CancellationError())) }

    private func complete(_ result: Result<[Product], Error>) {
        guard let waiter = continuation else { return }
        continuation = nil
        fetchTask?.cancel(); fetchTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        waiter.resume(with: result)
    }
}
