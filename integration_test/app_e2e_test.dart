import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rice_business_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Application Flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Login
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify MainScreen is displayed
    expect(find.text('Customers'), findsWidgets);

    // 2. Create Customer
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'E2E Test Customer');
    await tester.enterText(find.byType(TextFormField).at(1), '1234567890');
    await tester.enterText(find.byType(TextFormField).at(2), 'E2E Address');
    await tester.enterText(find.byType(TextFormField).at(3), '2000'); // Opening Balance
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('E2E Test Customer'), findsWidgets);

    // 3. Create Product
    await tester.tap(find.byIcon(Icons.inventory));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'E2E Ponni');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rice');
    await tester.enterText(find.byType(TextFormField).at(2), '25'); // Bag Size
    await tester.enterText(find.byType(TextFormField).at(3), '1200'); // Rate
    await tester.enterText(find.byType(TextFormField).at(4), '20'); // Min Stock
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('E2E Ponni - Rice'), findsWidgets);

    // 4. Stock In
    await tester.tap(find.byIcon(Icons.storefront));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Select Product from dropdown (assuming only 1 product in test DB)
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E2E Ponni - Rice').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '100'); // Quantity
    await tester.tap(find.text('Add Stock'));
    await tester.pumpAndSettle();

    expect(find.text('+100.0'), findsWidgets);

    // 5. Create Sale 1
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Select Customer
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E2E Test Customer').last);
    await tester.pumpAndSettle();

    // Select Product
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('E2E Ponni').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '10'); // Quantity
    await tester.enterText(find.byType(TextFormField).at(2), '5000'); // Paid
    await tester.tap(find.text('Complete Sale'));
    await tester.pumpAndSettle();

    // Verify Sale in list
    expect(find.text('₹12000.00'), findsWidgets);

    // Navigate back to More Menu
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Payment 1
    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Select Customer
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('E2E Test Customer').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '3000');
    await tester.tap(find.text('Receive Payment'));
    await tester.pumpAndSettle();

    // 7. Payment 2
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Select Customer
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('E2E Test Customer').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '2000');
    await tester.tap(find.text('Receive Payment'));
    await tester.pumpAndSettle();

    // Navigate back to More Menu
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 8. Sale 2
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Select Customer
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E2E Test Customer').last);
    await tester.pumpAndSettle();

    // Select Product
    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('E2E Ponni').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '5'); // Quantity
    await tester.enterText(find.byType(TextFormField).at(2), '0'); // Paid
    await tester.tap(find.text('Complete Sale'));
    await tester.pumpAndSettle();

    // We reached the end of the UI steps successfully.
  });
}
