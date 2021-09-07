//
// Created by Alex on 7.9.2021.
//

import Foundation
import SwiftUI
import UIKit
import FLAnimatedImage
import SnapKit

struct TemplateList: UIViewRepresentable {
  var templates: [TemplatePreview] = []
  let didSelectDocument: (UUID) -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  func makeUIView(context: Context) -> UICollectionView {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.createLayout())
    collectionView.showsVerticalScrollIndicator = false
    context.coordinator.collectionView = collectionView
    return collectionView
  }
  
  func updateUIView(_ uiView: UICollectionView, context: Context) {
    context.coordinator.didSelectItem = didSelectDocument
    if context.coordinator.templates != templates {
      context.coordinator.templates = templates
      context.coordinator.applySnapshot()
    }
  }
  
  class TemplateCell: UICollectionViewCell {
    var backkgroundView: UIView
    var imageView: FLAnimatedImageView
    var template: TemplatePreview?
    let contentInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    
    override init(frame: CGRect) {
      imageView = FLAnimatedImageView(frame: .zero)
      imageView.contentMode = .scaleAspectFill
      imageView.layer.cornerRadius = 16
      imageView.layer.masksToBounds = true
      imageView.alpha = 0
      
      backkgroundView = UIView(frame: .zero)
      backkgroundView.backgroundColor = .white.withAlphaComponent(0.08)
      backkgroundView.layer.cornerRadius = 16
      backkgroundView.layer.masksToBounds = true
      
      super.init(frame: frame)
      contentView.addSubview(backkgroundView)
      contentView.addSubview(imageView)
      
      imageView.snp.makeConstraints { maker in
        maker.edges.equalTo(backkgroundView)
      }
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    func clear() {
      imageView.animatedImage = nil
      self.imageView.alpha = 0
    }
    
    override func prepareForReuse() {
      clear()
      backkgroundView.snp.remakeConstraints { maker in
        maker.edges.equalToSuperview().inset(contentInsets).priority(.high)
        maker.height.equalTo(200).priority(.required)
      }
      super.prepareForReuse()
    }
    
    func configure(template: TemplatePreview) {
      self.template = template
      self.backkgroundView.snp.remakeConstraints { maker in
        maker.height.equalTo(self.backkgroundView.snp.width).multipliedBy(template.aspectRatio.height / template.aspectRatio.width).priority(.high)
        maker.height.lessThanOrEqualTo(self.backkgroundView.snp.width).priority(.required)
        maker.edges.equalToSuperview().inset(self.contentInsets)
      }
    }
    
    func play() {
      guard let template = template, let previewUrl = template.previewUrl else {
        return
      }
      
      DispatchQueue.global().async { [weak self] in
        if let image = try? FLAnimatedImage(animatedGIFData: Data(contentsOf: previewUrl)){
          DispatchQueue.main.async {
            if let self = self, let id = self.template?.id, id == template.id {
              self.imageView.animatedImage = image
              UIView.animate(withDuration: 0.3) {
                self.imageView.alpha = 1
              }
            }
          }
        }
      }
    }
    
    func pause() {
      clear()
    }
  }
  
  class Coordinator: NSObject, UICollectionViewDelegate {
    var templates: [TemplatePreview] = []
    var dataSource: UICollectionViewDiffableDataSource<Int, TemplatePreview>!
    var didSelectItem: ((UUID) -> Void)?

    var collectionView: UICollectionView? {
      didSet {
        if let collectionView = collectionView {
          collectionView.register(TemplateCell.self, forCellWithReuseIdentifier: "TemplateCell")
          dataSource = .init(collectionView: collectionView) { (collectionView, indexPath, template) -> UICollectionViewCell? in
            
            let registration = UICollectionView.CellRegistration<TemplateCell, TemplatePreview>.init(handler: { cell, indexPath, template in
              cell.configure(template: template)
            })
            
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: template)
          }
          collectionView.delegate = self
        }
      }
    }
    
    func createLayout() -> UICollectionViewLayout {
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(200))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: .fixed(8), trailing: nil, bottom: .fixed(8))
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(200))
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                     subitems: [item])
      
      let section = NSCollectionLayoutSection(group: group)
      let layout = UICollectionViewCompositionalLayout(section: section)
      return layout
    }
    
    func applySnapshot() {
      var snapshot = NSDiffableDataSourceSectionSnapshot<TemplatePreview>()
      snapshot.append(templates)
      dataSource.apply(snapshot, to: 0, animatingDifferences: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
      guard let cell = cell as? TemplateCell else {
        return
      }
      cell.play()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
      guard let cell = cell as? TemplateCell else {
        return
      }
      cell.pause()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      didSelectItem?(templates[indexPath.item].id)
    }
  }
}
