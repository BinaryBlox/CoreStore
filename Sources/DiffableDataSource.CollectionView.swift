//
//  DiffableDataSource.CollectionView.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(UIKit)

import UIKit
import CoreData


// MARK: - DiffableDataSource

extension DiffableDataSource {

    // MARK: - CollectionView

    open class CollectionView<O: DynamicObject>: NSObject, UICollectionViewDataSource {

        // MARK: Public

        public typealias ObjectType = O

        @nonobjc
        public init(collectionView: UICollectionView, dataStack: DataStack, cellProvider: @escaping (UICollectionView, IndexPath, O) -> UICollectionViewCell?, supplementaryViewProvider: @escaping (UICollectionView, String, IndexPath) -> UICollectionReusableView? = { _, _, _ in nil }) {

            self.collectionView = collectionView
            self.cellProvider = cellProvider
            self.supplementaryViewProvider = supplementaryViewProvider
            self.dataStack = dataStack

            super.init()

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                self.rawDataSource = UITableViewDiffableDataSource<String, O.ObjectID>(
//                    tableView: tableView,
//                    cellProvider: { [weak self] (tableView, indexPath, objectID) -> UITableViewCell? in
//
//                        guard let self = self else {
//
//                            return nil
//                        }
//                        guard let object = self.dataStack.fetchExisting(objectID) as O? else {
//
//                            return nil
//                        }
//                        return self.cellProvider(tableView, indexPath, object)
//                    }
//                )
//            }
//            else {

                self.rawDataSource = Internals.DiffableDataUIDispatcher<O>(dataStack: dataStack)
//            }

            collectionView.dataSource = self
        }

        public func apply(_ snapshot: ListSnapshot<O>, animatingDifferences: Bool = true) {

            let diffableSnapshot = snapshot.diffableSnapshot
//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                self.modernDataSource.apply(
//                    diffableSnapshot as! NSDiffableDataSourceSnapshot<String, NSManagedObjectID>,
//                    animatingDifferences: animatingDifferences,
//                    completion: nil
//                )
//            }
//            else {

                self.legacyDataSource.apply(
                    diffableSnapshot as! Internals.DiffableDataSourceSnapshot,
                    view: self.collectionView,
                    animatingDifferences: animatingDifferences,
                    performUpdates: { collectionView, changeset, setSections in

                        collectionView.reload(
                            using: changeset,
                            setData: setSections
                        )
                    }
                )
//            }
        }

        public func itemIdentifier(for indexPath: IndexPath) -> O.ObjectID? {

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                return self.modernDataSource.itemIdentifier(for: indexPath)
//            }
//            else {

                return self.legacyDataSource.itemIdentifier(for: indexPath)
//            }
        }

        public func indexPath(for itemIdentifier: O.ObjectID) -> IndexPath? {

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                return self.modernDataSource.indexPath(for: itemIdentifier)
//            }
//            else {

                return self.legacyDataSource.indexPath(for: itemIdentifier)
//            }
        }


        // MARK: - UICollectionViewDataSource

        @objc
        public dynamic func numberOfSections(in collectionView: UICollectionView) -> Int {

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                return self.modernDataSource.numberOfSections(in: tableView)
//            }
//            else {

                return self.legacyDataSource.numberOfSections()
//            }
        }

        @objc
        public dynamic func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                return self.modernDataSource.tableView(tableView, numberOfRowsInSection: section)
//            }
//            else {

                return self.legacyDataSource.numberOfItems(inSection: section)
//            }
        }

        @objc
        open dynamic func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

//            if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
//
//                return self.modernDataSource.tableView(tableView, cellForRowAt: indexPath)
//            }
//            else {

                guard let objectID = self.legacyDataSource.itemIdentifier(for: indexPath) else {

                    Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) already removed from list")
                }
                guard let object = self.dataStack.fetchExisting(objectID) as O? else {

                    Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) has been deleted")
                }
                guard let cell = self.cellProvider(collectionView, indexPath, object) else {

                    Internals.abort("\(Internals.typeName(UICollectionViewDataSource.self)) returned a `nil` cell for \(Internals.typeName(IndexPath.self)) \(indexPath)")
                }
                return cell
//            }
        }

        @objc
        open dynamic func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

            guard let view = self.supplementaryViewProvider(collectionView, kind, indexPath) else {

                return UICollectionReusableView()
            }
            return view
        }


        // MARK: Private

        private weak var collectionView: UICollectionView?

        private let dataStack: DataStack
        private let cellProvider: (UICollectionView, IndexPath, O) -> UICollectionViewCell?
        private let supplementaryViewProvider: (UICollectionView, String, IndexPath) -> UICollectionReusableView?
        private var rawDataSource: Any!

//        @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
//        private var modernDataSource: UITableViewDiffableDataSource<String, O.ObjectID> {
//
//            return self.rawDataSource as! UITableViewDiffableDataSource<String, O.ObjectID>
//        }

        private var legacyDataSource: Internals.DiffableDataUIDispatcher<O> {

            return self.rawDataSource as! Internals.DiffableDataUIDispatcher<O>
        }
    }
}


// MARK: - UICollectionView

extension UICollectionView {

    // MARK: FilePrivate

    @nonobjc
    fileprivate func reload<C, O>(
        using stagedChangeset: Internals.DiffableDataUIDispatcher<O>.StagedChangeset<C>,
        interrupt: ((Internals.DiffableDataUIDispatcher<O>.Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {

        if case .none = window, let data = stagedChangeset.last?.data {

            setData(data)
            self.reloadData()
            return
        }
        for changeset in stagedChangeset {

            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {

                setData(data)
                self.reloadData()
                return
            }
            self.performBatchUpdates(
                {
                    setData(changeset.data)

                    if !changeset.sectionDeleted.isEmpty {

                        self.deleteSections(IndexSet(changeset.sectionDeleted))
                    }
                    if !changeset.sectionInserted.isEmpty {

                        self.insertSections(IndexSet(changeset.sectionInserted))
                    }
                    if !changeset.sectionUpdated.isEmpty {

                        self.reloadSections(IndexSet(changeset.sectionUpdated))
                    }
                    for (source, target) in changeset.sectionMoved {

                        self.moveSection(source, toSection: target)
                    }
                    if !changeset.elementDeleted.isEmpty {

                        self.deleteItems(at: changeset.elementDeleted.map { IndexPath(row: $0.element, section: $0.section) })
                    }
                    if !changeset.elementInserted.isEmpty {

                        self.insertItems(at: changeset.elementInserted.map { IndexPath(row: $0.element, section: $0.section) })
                    }
                    if !changeset.elementUpdated.isEmpty {

                        self.reloadItems(at: changeset.elementUpdated.map { IndexPath(row: $0.element, section: $0.section) })
                    }
                    for (source, target) in changeset.elementMoved {

                        self.moveItem(at: IndexPath(row: source.element, section: source.section), to: IndexPath(row: target.element, section: target.section))
                    }
                },
                completion: nil
            )
        }
    }
}


#endif