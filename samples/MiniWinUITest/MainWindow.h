#pragma once
#include "MainWindow.g.h"

namespace winrt::MiniWinUITest::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void myButton_Click(const Windows::Foundation::IInspectable &sender, const Microsoft::UI::Xaml::RoutedEventArgs &args);

        winrt::Microsoft::UI::Xaml::Controls::Button::Click_revoker myButton_Click_revoker{};
    };
}
namespace winrt::MiniWinUITest::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
