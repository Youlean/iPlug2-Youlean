void GetApplePluginPath(char* dest, const char* bundleID)
{
    strcpy(dest, "/Applications/FL Studio 20.app/Contents/Resources/FL/Plugins/Fruity/Effects/IPlugEffect/IPlugEffect.dylib");
    return;
	NSBundle* pBundle = [NSBundle bundleWithIdentifier: @"com.AcmeInc.fruity.IPlugEffect"];

	if (pBundle)
	{
		NSString* path = [[pBundle bundlePath] stringByDeletingLastPathComponent];

		if (path)
		{
			strcpy(dest, [path UTF8String]);
		}
	}
}
