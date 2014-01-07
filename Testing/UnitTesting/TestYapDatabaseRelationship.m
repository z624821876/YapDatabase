#import <SenTestingKit/SenTestingKit.h>

#import "YapDatabase.h"
#import "YapDatabaseRelationship.h"
#import "TestNodes.h"

#import "DDLog.h"
#import "DDTTYLogger.h"


@interface TestYapDatabaseRelationship : SenTestCase
@end

@implementation TestYapDatabaseRelationship

- (NSString *)databasePath:(NSString *)suffix
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *databaseName = [NSString stringWithFormat:@"%@-%@.sqlite", THIS_FILE, suffix];
	
	return [baseDir stringByAppendingPathComponent:databaseName];
}

- (void)setUp
{
	[super setUp];
	[DDLog removeAllLoggers];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
}

- (void)tearDown
{
	[DDLog flushLog];
	[super tearDown];
}

#pragma mark -

- (void)testStandard
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection1 = [database newConnection];
	YapDatabaseConnection *connection2 = [database newConnection];
	
	YapDatabaseRelationship *relationship = [[YapDatabaseRelationship alloc] init];
	
	BOOL registered = [database registerExtension:relationship withName:@"relationship"];
	
	STAssertTrue(registered, @"Error registering extension");
	
	Node_Standard *n1 = [[Node_Standard alloc] init];
	Node_Standard *n2 = [[Node_Standard alloc] init];
	Node_Standard *n3 = [[Node_Standard alloc] init];
	
	n1.childKeys = @[ n2.key, n3.key ];
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting the children
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n2.key inCollection:nil];
		[transaction removeObjectForKey:n3.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Re-add the children and edges
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		// Re-add the children
		
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		// Reset the parent (so it re-adds the edges)
		
		[transaction replaceObject:n1 forKey:n1.key inCollection:nil];
		
		// Check that the edges are back
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting the parent
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"child"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		
		STAssertNil([transaction objectForKey:n2.key inCollection:nil], @"Oops");
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
	
	// Now test adding an edge and deleting it within the same transaction
	
	[connection2 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		
		[[transaction ext:@"relationship"] flush];
		
		STAssertNil([transaction objectForKey:n2.key inCollection:nil], @"Oops");
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
}

- (void)testInverse
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection1 = [database newConnection];
	YapDatabaseConnection *connection2 = [database newConnection];
	
	YapDatabaseRelationship *relationship = [[YapDatabaseRelationship alloc] init];
	
	BOOL registered = [database registerExtension:relationship withName:@"relationship"];
	
	STAssertTrue(registered, @"Error registering extension");
	
	Node_Inverse *n1 = [[Node_Inverse alloc] init];
	Node_Inverse *n2 = [[Node_Inverse alloc] init];
	Node_Inverse *n3 = [[Node_Inverse alloc] init];
	
	n2.parentKey = n1.key;
	n3.parentKey = n1.key;
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting 1 of the children.
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n2.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"parent"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting the parent.
	// This should also delete the second child (due to the nodeDeleteRules).
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		STAssertNil([transaction objectForKey:n2.key inCollection:nil], @"Oops");
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
}

- (void)testRetainCount
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection1 = [database newConnection];
	YapDatabaseConnection *connection2 = [database newConnection];
	
	YapDatabaseRelationship *relationship = [[YapDatabaseRelationship alloc] init];
	
	BOOL registered = [database registerExtension:relationship withName:@"relationship"];
	
	STAssertTrue(registered, @"Error registering extension");
	
	Node_RetainCount *n1 = [[Node_RetainCount alloc] init];
	Node_RetainCount *n2 = [[Node_RetainCount alloc] init];
	Node_RetainCount *n3 = [[Node_RetainCount alloc] init];
	
	// Node1 & Node2 will both retain Node3.
	//
	// Node1 -> Node3
	// Node2 -> Node3
	
	n1.retainedKey = n3.key;
	n2.retainedKey = n3.key;
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting 1 of the retainers.
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" destinationKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained" sourceKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n1.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retained"
		                                                       sourceKey:n2.key
		                                                      collection:nil
		                                                  destinationKey:n3.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting the second/last retainer.
	// This should also delete n3 (as no more nodes are retaining it).
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n2.key inCollection:nil];
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
}

- (void)testInverseRetainCount
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection1 = [database newConnection];
	YapDatabaseConnection *connection2 = [database newConnection];
	
	YapDatabaseRelationship *relationship = [[YapDatabaseRelationship alloc] init];
	
	BOOL registered = [database registerExtension:relationship withName:@"relationship"];
	
	STAssertTrue(registered, @"Error registering extension");
	
	Node_InverseRetainCount *n1 = [[Node_InverseRetainCount alloc] init];
	Node_InverseRetainCount *n2 = [[Node_InverseRetainCount alloc] init];
	Node_InverseRetainCount *n3 = [[Node_InverseRetainCount alloc] init];
	
	// Node1 & Node2 will both retain Node3.
	// But the edges are being created in reverse.
	//
	// Node3 -> Node1
	// Node3 -> Node2
	
	n3.retainerKeys = @[ n1.key, n2.key ];
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	[connection2 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting both of the retainers.
	// This should delete n3, because no nodes are left to retain it.
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		[transaction removeObjectForKey:n2.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Reset all the nodes
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		// Re-add the children
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		// Check that the edges are back
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 2, @"Bad edgeCount. expected(2) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Test deleting just one of the retainers.
	// This should not delete n3, as n2 is still retaining it.
	
	[connection1 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		
		NSUInteger edgeCount;
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" sourceKey:n3.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n1.key collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(0) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer" destinationKey:n2.key collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n1.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 0, @"Bad edgeCount. expected(0) != %d", (int)edgeCount);
		
		edgeCount = [[transaction ext:@"relationship"] edgeCountWithName:@"retainer"
		                                                       sourceKey:n3.key
		                                                      collection:nil
		                                                  destinationKey:n2.key
		                                                      collection:nil];
		STAssertTrue(edgeCount == 1, @"Bad edgeCount. expected(1) != %d", (int)edgeCount);
	}];
	
	// Now delete the last retainer (n2).
	// This should delete n3 as there are no other nodes retaining it.
	
	[connection2 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction removeObjectForKey:n2.key inCollection:nil];
	}];
	
	[connection1 readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
	
	// Now test adding the edges and deleting them within the same transaction
	
	[connection2 readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:n1 forKey:n1.key inCollection:nil];
		[transaction setObject:n2 forKey:n2.key inCollection:nil];
		[transaction setObject:n3 forKey:n3.key inCollection:nil];
		
		[transaction removeObjectForKey:n1.key inCollection:nil];
		[transaction removeObjectForKey:n2.key inCollection:nil];
		
		[[transaction ext:@"relationship"] flush];
		
		STAssertNil([transaction objectForKey:n3.key inCollection:nil], @"Oops");
	}];
}

@end