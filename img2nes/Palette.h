//
//  palette.h
//  CHREditor
//
//  Created by Jonatan Yde on 13/11/2023.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN



@interface Palette : NSObject

+(Palette *) sharedPalette;


-(void)setColor:(NSColor *) color at:(NSInteger)index;
-(void)setColorFrom:(NSString *) indexName at:(NSInteger)index;
-(NSColor*)colorAt:(NSInteger)index;
-(int)indexOf:(NSColor*)color;
-(NSArray*)getPalette;
-(NSArray*)getIndexedPalette;
-(NSColor*)getColorFromName:(NSString*)name;
-(NSString*)getNameFromColor:(NSColor*)color;
-(NSString*)getNameFromIndex:(NSInteger)index;
-(NSDictionary*)NESpalette;
@end

NS_ASSUME_NONNULL_END
