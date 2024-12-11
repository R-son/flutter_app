import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

const String addr = "192.168.1.58";

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String? category;
  String name = '';
  String description = '';
  double rating = 0.0;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('http://${addr}:3000/categories'));
      if (response.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $error')),
      );
    }
  }

  Future<void> addItem() async {
    final response = await http.post(
      Uri.parse('http://${addr}:3000/add-item'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "category": category,
        "name": name,
        "description": description,
        "rating": rating,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item added successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add item')));
      debugPrint("Response ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Item"),
        backgroundColor: Color(0xFF2F70AF),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Category"),
                value: category,
                items: categories.map<DropdownMenuItem<String>>((dynamic category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => category = value),
                validator: (value) => value == null || value.isEmpty ? "Category is required" : null,
                hint: Text("Select a category"),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Name"),
                onChanged: (value) => name = value,
                validator: (value) => value!.isEmpty ? "Name is required" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Description"),
                onChanged: (value) => description = value,
                validator: (value) => value!.isEmpty ? "Description is required" : null,
              ),
              Slider(
                value: rating,
                min: 0,
                max: 5,
                divisions: 10,
                label: rating.toString(),
                onChanged: (value) => setState(() => rating = value),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    addItem();
                  }
                },
                child: Text("Add Item"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}