#pragma once
#include "XamlApplication.g.h"

namespace winrt::MiniWinUITest::implementation
{
    struct XamlApplication : XamlApplicationT<XamlApplication>
    {
        XamlApplication() = default;
        XamlApplication(std::initializer_list<winrt::Microsoft::UI::Xaml::Markup::IXamlMetadataProvider>);

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const &);

        winrt::Windows::Foundation::Collections::IVector<winrt::Microsoft::UI::Xaml::Markup::IXamlMetadataProvider> Providers();
        winrt::Microsoft::UI::Xaml::Markup::IXamlType GetXamlType(winrt::Windows::UI::Xaml::Interop::TypeName const& type);
        winrt::Microsoft::UI::Xaml::Markup::IXamlType GetXamlType(hstring const& fullName);
        com_array<winrt::Microsoft::UI::Xaml::Markup::XmlnsDefinition> GetXmlnsDefinitions();

    private:
        winrt::Windows::Foundation::Collections::IVector<winrt::Microsoft::UI::Xaml::Markup::IXamlMetadataProvider> m_providers = nullptr;
        winrt::Microsoft::UI::Xaml::Window window = nullptr;
    };
}
