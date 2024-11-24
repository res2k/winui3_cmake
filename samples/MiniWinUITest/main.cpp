#include "pch.h"
#include <MddBootstrap.h>
#include <WindowsAppSDK-VersionInfo.h>

#include "XamlApplication.h"

struct bootstrap_winappsdk
{
	bootstrap_winappsdk()
	{
		winrt::check_hresult(MddBootstrapInitialize2(WINDOWSAPPSDK_RELEASE_MAJORMINOR, WINDOWSAPPSDK_RELEASE_VERSION_TAG_W, PACKAGE_VERSION{}, MddBootstrapInitializeOptions_None));
	}
	~bootstrap_winappsdk()
	{
		MddBootstrapShutdown();
	}
};
struct apartment_init
{
	apartment_init()
	{
		winrt::init_apartment(winrt::apartment_type::single_threaded);
	}
	~apartment_init()
	{
		winrt::uninit_apartment();
	}
};

static apartment_init s_init_apartment;
static bootstrap_winappsdk s_winappsdk_bootstrap;

int APIENTRY wWinMain(_In_ HINSTANCE, _In_opt_ HINSTANCE, _In_ LPWSTR, _In_ int)
{
	winrt::Microsoft::UI::Xaml::Application::Start(
		[](auto &&)
		{
			auto metadata_provider = winrt::Microsoft::UI::Xaml::XamlTypeInfo::XamlControlsXamlMetaDataProvider();

			winrt::make<winrt::MiniWinUITest::implementation::XamlApplication>(std::initializer_list<winrt::Microsoft::UI::Xaml::Markup::IXamlMetadataProvider>{ metadata_provider });
		}
	);

	return 0;
}