import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit.dart';
import 'dart:core';

const String addr = "192.168.1.58";

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> categories = [];
  List<dynamic> items = [];
  String? selectedCategory = "All Categories"; // Default to "All Categories"
  String? selectedSortOption = 'Name (A-Z)'; // Default sort option

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchItems(selectedCategory); // Fetch all items by default
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('http://$addr:3000/categories'));
      if (response.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      setState(() {
        categories = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $error')),
      );
    }
  }

  Future<void> fetchItems(String? category) async {
    try {
      final response = category == "All Categories"
          ? await http.get(Uri.parse('http://$addr:3000/items')) // Fetch all items
          : await http.get(Uri.parse('http://$addr:3000/items?category=$category')); // Fetch items for a specific category

      if (response.statusCode == 200) {
        setState(() {
          items = json.decode(response.body);
        });
        sortItems(selectedSortOption); // Sort items after fetching
      } else {
        throw Exception('Failed to load items');
      }
    } catch (error) {
      setState(() {
        items = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading items: $error')),
      );
    }
  }

  void sortItems(String? sortOption) {
    if (sortOption == 'Name (A-Z)') {
      items.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (sortOption == 'Name (Z-A)') {
      items.sort((a, b) => b['name'].compareTo(a['name']));
    } else if (sortOption == 'Rating (High to Low)') {
      items.sort((a, b) => b['rating'].compareTo(a['rating']));
    } else if (sortOption == 'Rating (Low to High)') {
      items.sort((a, b) => a['rating'].compareTo(b['rating']));
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      final response = await http.delete(Uri.parse('http://$addr:3000/delete-item/$itemId'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item deleted successfully')),
        );
        if (selectedCategory != null) {
          fetchItems(selectedCategory); // Refresh the item list
        }
      } else {
        throw Exception('Failed to delete item');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
        backgroundColor: Color(0xFF2F70AF),
      ),
      body: categories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a Category:", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: [
                      DropdownMenuItem<String>(
                        value: "All Categories",
                        child: Text("All Categories"),
                      ),
                      ...categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        fetchItems(value); // Fetch items based on selected category
                      });
                    },
                    hint: Text("Choose a category"),
                  ),

                  SizedBox(height: 20),
                  Text("Sort Items By:", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedSortOption,
                    items: [
                      'Name (A-Z)',
                      'Name (Z-A)',
                      'Rating (High to Low)',
                      'Rating (Low to High)',
                    ].map<DropdownMenuItem<String>>((sortOption) {
                      return DropdownMenuItem<String>(
                        value: sortOption,
                        child: Text(sortOption),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSortOption = value;
                        sortItems(value); // Sort items based on selected sort option
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  if (items.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item['name']),
                            subtitle: Text("Rating: ${item['rating'].toStringAsFixed(1)}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditItemScreen(item: item),
                                      ),
                                    );
                                    if (updated == true && selectedCategory != null) {
                                      fetchItems(selectedCategory); // Refresh items after update
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Delete Item"),
                                          content: Text("Are you sure you want to delete '${item['name']}'?"),
                                          actions: [
                                            TextButton(
                                              child: Text("Cancel"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text("Delete"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                deleteItem(item['id']);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (items.isEmpty && selectedCategory != null)
                    Center(child: Text("No items found for the selected category.")),
                ],
              ),
            ),
    );
  }
}
