#include "pch.h"
#include "MainWindow.h"
#include "MainWindow.g.cpp"

namespace winrt::MiniWinUITest::implementation
{
	MainWindow::MainWindow()
	{
		auto c_base = Microsoft::UI::Xaml::Controls::StackPanel();
		c_base.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Center);
		c_base.HorizontalAlignment(Microsoft::UI::Xaml::HorizontalAlignment::Center);
		c_base.Orientation(Microsoft::UI::Xaml::Controls::Orientation::Horizontal);
		auto c_btn = Microsoft::UI::Xaml::Controls::Button();
		c_btn.Content(box_value(L"Click Me!"));
		c_btn.Name(L"myButton");
		myButton_Click_revoker = c_btn.Click(auto_revoke, {this, &MainWindow::myButton_Click});
		c_base.Children().Append(c_btn);

		Content(c_base);
	}

	void MainWindow::myButton_Click(const Windows::Foundation::IInspectable &sender, const Microsoft::UI::Xaml::RoutedEventArgs &)
	{
		auto me = sender.as<Microsoft::UI::Xaml::Controls::Button>();

		me.Content(box_value(L"Clicked!"));
	}
}
