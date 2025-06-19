import UIKit

extension UICollectionView {
  /// Dequeues a cell of the provided `cellType` after first registering it.
  ///
  /// - parameter cellType: The type of cell to dequeue.
  /// - parameter indexPath: The index path of the cell to dequeue.
  func autoDequeueCell<T: UICollectionViewCell>(
    ofType _: T.Type,
    for indexPath: IndexPath
  ) -> T {
    let reuseIdentifier = String(describing: T.self)

    register(T.self, forCellWithReuseIdentifier: reuseIdentifier)

    return dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! T
  }
}
