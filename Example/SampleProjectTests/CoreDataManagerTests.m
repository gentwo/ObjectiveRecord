#import "Kiwi.h"
#import <ObjectiveRecord/CoreDataManager.h>
#import <ObjectiveSugar.h>
#import "Person.h"

void resetCoreDataStack(CoreDataManager *manager) {
    [manager setValue:nil forKey:@"persistentStoreCoordinator"];
    [manager setValue:nil forKey:@"managedObjectContext"];
    [manager setValue:nil forKey:@"managedObjectModel"];
}

void printPersons(NSArray *persons) {
    NSLog(@"Printing persons....");
    [persons each:^(Person *person) {
        NSLog(@"%@, %@", person.firstName, person.lastName);
    }];
    NSLog(@"Printing persons....complete");
}

SPEC_BEGIN(CoreDataManagerTests)

describe(@"Core data stack", ^{
   
    CoreDataManager *manager = [CoreDataManager new];

    afterEach(^{
        resetCoreDataStack(manager);
    });
    
    it(@"can use in-memory store", ^{
        [manager useInMemoryStore];
        NSPersistentStore *store = [manager.persistentStoreCoordinator persistentStores][0];
        [[store.type should] equal:NSInMemoryStoreType];
    });
    
    it(@"uses documents directory on iphone", ^{
        [manager stub:@selector(isOSX) andReturn:theValue(NO)];
        NSPersistentStore *store = manager.persistentStoreCoordinator.persistentStores[0];
        [[store.URL.absoluteString should] containString:[manager applicationDocumentsDirectory].absoluteString];
    });
    
    it(@"uses application support directory on osx", ^{
        [manager stub:@selector(isOSX) andReturn:theValue(YES)];
        NSPersistentStore *store = manager.persistentStoreCoordinator.persistentStores[0];
        [[store.URL.absoluteString should] containString:[manager applicationSupportDirectory].absoluteString];
    });
    
    it(@"creates application support directory on OSX if needed", ^{
        [manager stub:@selector(isOSX) andReturn:theValue(YES)];
        [[NSFileManager defaultManager] removeItemAtURL:manager.applicationSupportDirectory error:nil];

        NSPersistentStore *store = [manager.persistentStoreCoordinator persistentStores][0];
        [[store.URL.absoluteString should] endWithString:@".sqlite"];
    });

    it(@"deletes and recreates store", ^{
        [manager stub:@selector(isOSX) andReturn:theValue(YES)];
        [manager resetStore];
        NSPersistentStore *store = [manager.persistentStoreCoordinator persistentStores][0];
        [[store.URL shouldNot] beNil];
        NSUInteger baseCount = Person.count;
        Person *person = [Person create:@{
                                          @"firstName" : @"test",
                                          @"lastName" : @"last",
                                          @"age" : @(43),
                                          @"isMember" : @YES,
                                          @"anniversary" : [NSDate dateWithTimeIntervalSince1970:0]
                                          }];
        [person save];
        printPersons(Person.all);
        [[theValue(Person.count) should] equal:theValue(baseCount+1)];
        [[theValue([manager resetStore]) should] beYes];
        NSArray *persons  = [Person all];
        printPersons(persons);
        [[theValue(persons.count) should] equal:theValue(0)];
    });

});

SPEC_END
