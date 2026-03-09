import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Importa el paquete shimmer

/// Un widget de esqueleto de carga para la página de inicio,
/// adaptado al diseño de desplazamiento horizontal.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Color base del efecto shimmer
      highlightColor: Colors.grey[100]!, // Color de resaltado del efecto shimmer
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton para "Good Morning" y dirección
              Container(height: 20, width: 150, color: Colors.white), // Usar color blanco para que el shimmer se vea
              const SizedBox(height: 8),
              Container(height: 16, width: 200, color: Colors.white),
              const SizedBox(height: 24),
              // Skeleton para la barra de búsqueda
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para categorías
              Container(height: 30, width: 120, color: Colors.white),
              const SizedBox(height: 16),
              SizedBox(
                height: 90, // Altura fija para la fila de categorías
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para sección de productos recomendados
              Container(height: 24, width: 150, color: Colors.white),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Altura aproximada de la ProductCard
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Container(
                    width: 180, // Ancho aproximado de la ProductCard
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para banner "Invite friends"
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para sección de productos con descuento
              Container(height: 24, width: 180, color: Colors.white),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para sección de nuevas recetas
              Container(height: 24, width: 150, color: Colors.white),
              const SizedBox(height: 16),
              SizedBox(
                height: 200, // Altura aproximada de la RecipeCard
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                  itemBuilder: (context, index) => Container(
                    width: 150, // Ancho aproximado de la RecipeCard
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Skeleton para sección de tiendas
              Container(height: 24, width: 100, color: Colors.white),
              const SizedBox(height: 16),
              SizedBox(
                height: 100, // Altura aproximada de la ShopLogoCard
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Container(
                    width: 100, // Ancho aproximado de la ShopLogoCard
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
