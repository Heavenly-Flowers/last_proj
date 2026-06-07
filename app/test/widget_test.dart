import 'package:app/cart/cart_item.dart';
import 'package:app/cart/cart_screen.dart';
import 'package:app/cart/cart_service.dart';
import 'package:app/models/app_user.dart';
import 'package:app/models/coffee.dart';
import 'package:app/models/coffee_option.dart';
import 'package:app/models/order_status.dart';
import 'package:app/screens/auth_screen.dart';
import 'package:app/screens/coffee_details_screen.dart';
import 'package:app/screens/orders_history_screen.dart';
import 'package:app/widgets/order_status_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    CartService.instance.clear();
  });

  test('AppUser распознаёт роль администратора', () {
    final user = AppUser.fromJson({
      'id': 'test-id',
      'email': 'admin@example.com',
      'full_name': 'Администратор',
      'role': 'admin',
    });

    expect(user.isAdmin, isTrue);
    expect(user.role.displayName, 'Администратор');
  });

  test('CartItem рассчитывает размер и топпинги', () {
    final item = CartItem(
      coffee: Coffee(
        title: 'Латте',
        description: 'Кофе',
        price: 200,
        imageUrl: '',
      ),
      size: CoffeeOptions.sizes[2],
      toppings: [CoffeeOptions.toppings[0], CoffeeOptions.toppings[2]],
    );

    expect(item.size.extraPrice, 60);
    expect(item.toppingsPrice, 50);
    expect(item.totalPrice, 310);
  });

  test('CartService уведомляет интерфейс после добавления', () {
    var notifications = 0;
    void listener() => notifications++;

    final cart = CartService.instance;
    cart.addListener(listener);

    cart.addItem(
      CartItem(
        coffee: Coffee(
          title: 'Эспрессо',
          description: 'Кофе',
          price: 150,
          imageUrl: '',
        ),
        size: CoffeeOptions.sizes.first,
        toppings: const [],
      ),
    );

    expect(cart.itemCount, 1);
    expect(cart.totalPrice, 150);
    expect(notifications, 1);

    cart.removeListener(listener);
  });

  test('Прогресс заказа соответствует пяти статусам', () {
    expect(OrderStatuses.progressOf('Обработка'), 0.2);
    expect(OrderStatuses.progressOf('Готовится'), 0.6);
    expect(OrderStatuses.progressOf('Выдан'), 1);
    expect(OrderStatuses.nextAfter('Выдан'), isNull);
  });

  testWidgets('Открытая корзина обновляется после добавления товара', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CartScreen()));

    expect(find.text('Корзина пуста'), findsOneWidget);

    CartService.instance.addItem(
      CartItem(
        coffee: Coffee(
          title: 'Капучино',
          description: 'Кофе',
          price: 220,
          imageUrl: '',
        ),
        size: CoffeeOptions.sizes[1],
        toppings: const [],
      ),
    );
    await tester.pump();

    expect(find.text('Капучино'), findsOneWidget);
    expect(find.text('Итого: 250 ₽'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Корзина пуста'), findsOneWidget);
  });

  testWidgets('Экран входа переключается на регистрацию', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Вход в аккаунт'), findsOneWidget);

    await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
    await tester.pump();

    expect(find.text('Создание аккаунта'), findsOneWidget);
    expect(find.text('Зарегистрироваться'), findsOneWidget);
    expect(find.text('Имя'), findsOneWidget);
  });

  testWidgets('Карточка истории показывает готовность и открывается', (
    tester,
  ) async {
    var wasOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderHistoryCard(
            order: {
              'id': 42,
              'status': 'Готовится',
              'total_price': 300,
              'items': [
                {'coffee': 'Латте', 'size': 'L'},
              ],
            },
            onTap: () {
              wasOpened = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Заказ #42'), findsOneWidget);
    expect(find.text('Этап 3 из 5'), findsOneWidget);
    expect(find.byType(OrderStatusProgress), findsOneWidget);

    await tester.tap(find.text('Заказ #42'));
    await tester.pump();

    expect(wasOpened, isTrue);
  });

  testWidgets('Цена на кнопке меняется после выбора размера и топпинга', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoffeeDetailsScreen(
          coffee: Coffee(
            title: 'Латте',
            description: 'Кофе',
            price: 200,
            imageUrl: '',
          ),
        ),
      ),
    );

    expect(find.text('Добавить в корзину • 230 ₽'), findsOneWidget);

    await tester.tap(find.text('L'));
    await tester.pump();

    expect(find.text('Добавить в корзину • 260 ₽'), findsOneWidget);

    await tester.ensureVisible(find.text('Корица'));
    await tester.pump();
    await tester.tap(find.text('Корица'));
    await tester.pump();

    expect(find.text('Добавить в корзину • 270 ₽'), findsOneWidget);

    await tester.ensureVisible(find.text('Добавить в корзину • 270 ₽'));
    await tester.pump();
    await tester.tap(find.text('Добавить в корзину • 270 ₽'));
    await tester.pump();

    expect(CartService.instance.itemCount, 1);
    expect(CartService.instance.totalPrice, 270);
  });
}
