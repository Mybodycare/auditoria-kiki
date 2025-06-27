class CafeinaItem {
  final String name;
  final int caffeineMg;
  final List<String> aliases;

  CafeinaItem({
    required this.name,
    required this.caffeineMg,
    required this.aliases,
  });
}

class CafeinaService {
  final List<CafeinaItem> _items = [
    CafeinaItem(
      name: 'Café expreso',
      caffeineMg: 63,
      aliases: ['espresso', 'café solo', 'cafe solo', 'café expresso', 'cafe expresso'],
    ),
    CafeinaItem(
      name: 'Café americano',
      caffeineMg: 95,
      aliases: ['americano', 'café americano', 'cafe americano'],
    ),
    CafeinaItem(
      name: 'Café con leche',
      caffeineMg: 63,
      aliases: ['café con leche', 'cafe con leche', 'café leche', 'cafe leche'],
    ),
    CafeinaItem(
      name: 'Té verde',
      caffeineMg: 28,
      aliases: ['té verde', 'te verde', 'green tea'],
    ),
    CafeinaItem(
      name: 'Té negro',
      caffeineMg: 47,
      aliases: ['té negro', 'te negro', 'black tea'],
    ),
    CafeinaItem(
      name: 'Red Bull',
      caffeineMg: 80,
      aliases: ['redbull', 'red bull', 'red bull energy drink'],
    ),
    CafeinaItem(
      name: 'Monster Energy',
      caffeineMg: 160,
      aliases: ['monster', 'monster energy', 'monster energy drink'],
    ),
    CafeinaItem(
      name: 'Coca-Cola',
      caffeineMg: 34,
      aliases: ['coca cola', 'coca-cola', 'coca', 'cola', 'coke'],
    ),
    CafeinaItem(
      name: 'Pepsi',
      caffeineMg: 38,
      aliases: ['pepsi', 'pepsi cola'],
    ),
    CafeinaItem(
      name: 'Yerba mate',
      caffeineMg: 85,
      aliases: ['mate', 'yerba mate', 'tereré', 'terere'],
    ),
    CafeinaItem(
      name: 'Matcha',
      caffeineMg: 70,
      aliases: ['matcha', 'té matcha', 'te matcha', 'green tea matcha'],
    ),
    CafeinaItem(
      name: 'Guaraná',
      caffeineMg: 50,
      aliases: ['guarana', 'guaraná', 'guarana natural'],
    ),
  ];

  Future<CafeinaItem?> buscarPorNombreOAlias(String input) async {
    input = input.toLowerCase().trim();
    
    for (var item in _items) {
      if (item.name.toLowerCase() == input) {
        return item;
      }
      
      for (var alias in item.aliases) {
        if (alias.toLowerCase() == input) {
          return item;
        }
      }
    }
    
    return null;
  }
} 