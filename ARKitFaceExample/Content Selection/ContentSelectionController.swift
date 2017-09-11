/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller to support selection of virtual content.
*/

import UIKit

class ContentCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: ContentCell.self)
    
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                imageView.backgroundColor = .lightGray
            } else {
                imageView.backgroundColor = .clear
            }
        }
    }
}

class ContentSelectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var selectedVirtualContent: VirtualContentType = .none

    /// Invoked when the `selectedVirtualContent` property changes.
    var selectionHandler: (VirtualContentType) -> Void = { _ in }

    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 292, height: 73)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let itemIndex = selectedVirtualContent.rawValue
        let indexPath = IndexPath(item: itemIndex, section: 0)
        collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VirtualContentType.orderedValues.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentCell.reuseIdentifier, for: indexPath) as? ContentCell else {
            fatalError("Expected `\(ContentCell.self)` type for reuseIdentifier \(ContentCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }

        let content = VirtualContentType(rawValue: indexPath.item)!
        cell.imageView?.image = UIImage(named: content.imageName)
        cell.isSelected = indexPath.item == selectedVirtualContent.rawValue
        
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedVirtualContent = VirtualContentType(rawValue: indexPath.item)!
        selectionHandler(selectedVirtualContent)
        dismiss(animated: true, completion: nil)
    }
}
