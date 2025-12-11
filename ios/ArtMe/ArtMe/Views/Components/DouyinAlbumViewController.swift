import UIKit
import Photos

final class DouyinAlbumViewController: UIViewController {

    // 选中图片后的回调
    var onSelectImage: ((UIImage) -> Void)?

    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "选择照片"

        setupCollectionView()

        // 请求权限 + 拉取资源
        DouyinAlbumManager.shared.prepareLibrary { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.collectionView.reloadData()
            } else {
                self.showNoPermissionHint()
            }
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 1
        let columns: CGFloat = 3

        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - (columns - 1) * spacing) / columns
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        // 告诉 Manager 缩略图目标尺寸
        DouyinAlbumManager.shared.setThumbnailSize(CGSize(width: itemWidth * UIScreen.main.scale,
                                                           height: itemWidth * UIScreen.main.scale))

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true

        collectionView.register(DouyinAlbumCell.self,
                                forCellWithReuseIdentifier: "DouyinAlbumCell")

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func showNoPermissionHint() {
        let label = UILabel()
        label.text = "无法访问照片，请在系统设置中打开相册权限。"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
}

// MARK: - UICollectionViewCell

final class DouyinAlbumCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

// MARK: - DataSource & Delegate

extension DouyinAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return DouyinAlbumManager.shared.numberOfItems()
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DouyinAlbumCell",
                                                            for: indexPath) as? DouyinAlbumCell else {
            return UICollectionViewCell()
        }

        if let asset = DouyinAlbumManager.shared.asset(at: indexPath) {
            DouyinAlbumManager.shared.requestThumbnail(for: asset) { image in
                // 避免复用时错位
                DispatchQueue.main.async {
                    if collectionView.indexPath(for: cell) == indexPath {
                        cell.imageView.image = image
                    }
                }
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        guard let asset = DouyinAlbumManager.shared.asset(at: indexPath) else { return }

        DouyinAlbumManager.shared.requestFullImage(for: asset) { [weak self] image in
            guard let self = self, let image = image else { return }
            DispatchQueue.main.async {
                self.onSelectImage?(image)
            }
        }
    }
}


