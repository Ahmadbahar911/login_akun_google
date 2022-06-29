import 'package:flutter/material.dart';
import 'package:login_akun_google/bantuan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
const HomePage({Key? key}) : super(key: key);
@override
_HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
// text fields' controllers
var filter = "";
final TextEditingController _namaController = TextEditingController();
final TextEditingController _satuanController = TextEditingController();
final TextEditingController _hargaController = TextEditingController();
final CollectionReference _productss =
FirebaseFirestore.instance.collection('products$namauser');
Future<void> _filter([DocumentSnapshot? documentSnapshot]) async {
await showModalBottomSheet(
isScrollControlled: true,
context: context,
builder: (BuildContext ctx) {
return Padding(
padding: EdgeInsets.only(
top: 20,
left: 20,
right: 20,
// prevent the soft keyboard from covering text fields
bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextField(
  controller: _satuanController,
decoration: const InputDecoration(labelText: 'satuan'),
),
const SizedBox(
height: 20,
),
ElevatedButton(
child: Text('Filter'),
onPressed: () {
setState(() {
filter = _satuanController.text;
_satuanController.text = '';
});
Navigator.of(context).pop();
},
)
],
),
);
});
}
// This function is triggered when the floatting button or one of the edit buttons is pressed
// Adding a product if no documentSnapshot is passed
// If documentSnapshot != null then update an existing product
Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
String action = 'create';
if (documentSnapshot != null) {
action = 'update';
_namaController.text = documentSnapshot['nama'];
_satuanController.text = documentSnapshot['satuan'];
_hargaController.text = documentSnapshot['harga'].toString();
}
await showModalBottomSheet(
isScrollControlled: true,
context: context,
builder: (BuildContext ctx) {
return Padding(
padding: EdgeInsets.only(
top: 20,
left: 20,
right: 20,
// prevent the soft keyboard from covering text fields
bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextField(
controller: _namaController,
decoration: const InputDecoration(labelText: 'nama'),
),
TextField(
controller: _satuanController,
decoration: const InputDecoration(labelText: 'satuan'),
),
TextField(
keyboardType:
const TextInputType.numberWithOptions(decimal: true),
controller: _hargaController,
decoration: const InputDecoration(
labelText: 'harga',
),
),
const SizedBox(
height: 20,
),
ElevatedButton(
child: Text(action == 'create' ? 'Create' : 'Update'),
onPressed: () async {
final String? nama = _namaController.text;
final String? satuan = _satuanController.text;
final double? harga =
double.tryParse(_hargaController.text);
if (nama != null && satuan != null && harga != null) {
if (action == 'create') {
// Persist a new product to Firestore
await _productss.add(
{"nama": nama, "satuan": satuan, "harga": harga});
}
if (action == 'update') {
// Update the product
await _productss.doc(documentSnapshot!.id).update(
{"nama": nama, "satuan": satuan, "harga": harga});
}
// Clear the text fields
_namaController.text = '';
_satuanController.text = '';
_hargaController.text = '';
// Hide the bottom sheet
Navigator.of(context).pop();
}
},
)
],
),
);
});
}
// Deleteing a product by id
Future<void> _deleteProduct(String productId) async {
showDialog(
context: context,
builder: (BuildContext ctx) {
return AlertDialog(
title: Text("Hapus Data"),
content: Text("Apakah anda yakin?"),
actions: [
TextButton(
onPressed: () async {
await _productss.doc(productId).delete();
// Show a snackbar
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
content:
Text('You have successfully deleted a product')));
Navigator.pop(context);
},
child: const Text('Ya')),
TextButton(
onPressed: () {
Navigator.pop(context);
},
child: const Text('Tidak'))
],
);
});
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Latihan Firestore' ),
),
// Using StreamBuilder to display all products from Firestore in real-time
body: StreamBuilder(
stream: (filter.toString().isNotEmpty)
? _productss.where('satuan', isEqualTo: filter).snapshots()
: _productss.orderBy('nama').snapshots(),
builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
if (streamSnapshot.hasData) {
return ListView.builder(
itemCount: streamSnapshot.data!.docs.length,
itemBuilder: (context, index) {
final DocumentSnapshot documentSnapshot =
streamSnapshot.data!.docs[index];
return Card(
margin: const EdgeInsets.all(2),
child: ListTile(
title: Text(documentSnapshot['nama']),
//subtitle: Text(documentSnapshot['harga'].toString()),
subtitle: Column(
mainAxisAlignment: MainAxisAlignment.start,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(documentSnapshot['satuan'].toString()),
Text(documentSnapshot['harga'].toString()),
],
),
trailing: SizedBox(
width: 100,
child: Row(
children: [
// Press this button to edit a single product
IconButton(
icon: const Icon(Icons.edit),
onPressed: () =>
_createOrUpdate(documentSnapshot)),
// This icon button is used to delete a single product
IconButton(
icon: const Icon(Icons.delete),
onPressed: () =>
_deleteProduct(documentSnapshot.id)),
],
),
),
),
);
},
);
}
return const Center(
child: CircularProgressIndicator(),
);
},
),
// Add new product
floatingActionButton: Padding(
padding: const EdgeInsets.all(8.0),
child: Row(
mainAxisAlignment: MainAxisAlignment.end,
crossAxisAlignment: CrossAxisAlignment.center,
children: [
FloatingActionButton(
onPressed: () => _createOrUpdate(),
child: const Icon(Icons.add),
),
FloatingActionButton(
onPressed: () => _filter(),
child: const Icon(Icons.search),
),
],
),
),
);
}
}