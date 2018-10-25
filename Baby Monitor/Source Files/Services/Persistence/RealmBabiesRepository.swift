//
//  RealmBabiesRepository.swift
//  Baby Monitor
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa

final class RealmBabiesRepository: BabiesRepository {
    
    enum UpdateType {
        case name(Baby)
        case image(Baby)
    }
    
    lazy var babyUpdateObservable = babyPublisher.asObservable()
    var currentBabyId: String? {
        didSet {
            guard let currentBabyId = currentBabyId else {
                return
            }
            let realmBaby = realm.object(ofType: RealmBaby.self, forPrimaryKey: currentBabyId)
            currentBabyToken = realmBaby?.observe({ _ in
                guard let baby = self.realm.object(ofType: RealmBaby.self, forPrimaryKey: currentBabyId)?.toBaby() else {
                    return
                }
                self.babyPublisher.accept(baby)
            })
        }
    }
    
    private var babyPublisher = PublishRelay<Baby>()
    private let realm: Realm
    private var observations = [ObjectIdentifier: Observation]()
    private var currentBabyToken: NotificationToken?
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    func save(baby: Baby) throws {
        let realmBaby = RealmBaby(with: baby)
        try! realm.write {
            realm.add(realmBaby, update: true)
        }
    }
    
    func fetchAllBabies() -> [Baby] {
        let babies = realm.objects(RealmBaby.self)
            .map { $0.toBaby() }
        return Array(babies)
    }
    
    func removeAllBabies() {
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func fetchBaby(id: String) -> Baby? {
        return realm.object(ofType: RealmBaby.self, forPrimaryKey: id)?
            .toBaby()
    }
    
    func fetchBabies(name: String) -> [Baby] {
        let babies = realm.objects(RealmBaby.self)
            .filter { $0.name == name }
            .map { $0.toBaby() }
        return Array(babies)
    }
    
    func setPhoto(_ photo: UIImage, id: String) {
        try! realm.write {
            guard let photoData = photo.pngData() else { return }
            _ = realm.create(RealmBaby.self, value: ["id": id, "photoData": photoData], update: true)
                .toBaby()
        }
    }
    
    func setName(_ name: String, id: String) {
        try! realm.write {
            _ = realm.create(RealmBaby.self, value: ["id": id, "name": name], update: true)
                .toBaby()
        }
    }
}

extension RealmBabiesRepository {
    
    func addObserver(_ observer: BabyRepoObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    func removeObserver(_ observer: BabyRepoObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
}

private extension RealmBabiesRepository {
    
    struct Observation {
        weak var observer: BabyRepoObserver?
    }
    
    func babyDidChange(updateType: UpdateType) {
        for (id, observation) in observations {
            // If the observer is no longer in memory, we
            // can clean up the observation for its ID
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                continue
            }
            
            switch updateType {
            case .image(let baby):
                observer.babyRepo(self, didChangePhotoOf: baby)
            case .name(let baby):
                observer.babyRepo(self, didChangeNameOf: baby)
            }
        }
    }
}
