import 'package:app_autismo/resources/strings_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/usuario.dart';
import 'login.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  String nombre = "", ciudad = "", escuela = "", grado = "", correo = "", contrasena = "";
  int edad = 0;

  Future<void> _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final box = Hive.box<Usuario>(AppStrings.usuario);
      final usuario = Usuario(
        nombre: nombre,
        edad: edad,
        ciudad: ciudad,
        escuela: escuela,
        grado: grado,
        correo: correo,
        contrasena: contrasena,
      );
      await box.add(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.registroExito)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.crearCuenta)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.nombreLabel),
                validator: (v) => v!.isEmpty ? AppStrings.nombreValidator: null,
                onSaved: (v) => nombre = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText:AppStrings.edadLabel ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? AppStrings.edadValidator : null,
                onSaved: (v) => edad = int.parse(v!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.ciudadLabel),
                onSaved: (v) => ciudad = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.escuelaLabel),
                onSaved: (v) => escuela = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.gradoLabel),
                onSaved: (v) => grado = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.correoLabel),
                validator: (v) => v!.isEmpty ? AppStrings.correoValidator: null,
                onSaved: (v) => correo = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.contrasenaLabel),
                obscureText: true,
                validator: (v) => v!.isEmpty ? AppStrings.correoValidator: null,
                onSaved: (v) => contrasena = v!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrarUsuario,
                child: const Text(AppStrings.registrarseBoton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}