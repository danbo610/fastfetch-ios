#import <UIKit/UIKit.h>
#import <stdio.h>

int main(void) {
    @autoreleasepool {
        UIScreen *screen = [UIScreen mainScreen];

        CGSize nativeSize = screen.nativeBounds.size;
        CGFloat nativeScale = screen.nativeScale;

        printf("%.0fx%.0f %.2f\n",
               nativeSize.width,
               nativeSize.height,
               nativeScale);
    }

    return 0;
}