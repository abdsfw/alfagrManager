import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'cubit/app_cubit.dart';
import 'data/database_helper.dart';
import 'feature/app/presentation/view/page/app_root_page.dart';
import 'core/constant/keys.dart';
import 'core/theme/app_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppCubit()..loadInitialData(),
      child: MaterialApp(
        locale: const Locale('ar'),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar')],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        title: 'إدارة النادي القرآني',
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: AppColor.pForest2,
            onPrimary: AppColor.tWhite,
            secondary: AppColor.sGoldenWheat2,
            onSecondary: AppColor.tCharcoal2,
            error: AppColor.cRed,
            onError: AppColor.tWhite,
            surface: AppColor.sGoldenWheat1,
            onSurface: AppColor.tCharcoal2,
          ),
          scaffoldBackgroundColor: AppColor.sGoldenWheat1,
          useMaterial3: true,
          fontFamily: Keys.kFontFamily,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColor.pForest2,
            foregroundColor: AppColor.tWhite,
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: AppColor.tWhite,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColor.tWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.sGoldenWheat2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.sGoldenWheat2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColor.pForest2,
                width: 1.5,
              ),
            ),
          ),
        ),
        home: const AppRootPage(),
      ),
    );
  }
}
