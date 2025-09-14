import sqlite3
import graphviz
import os
import subprocess

DB_FILE = "library.db"
SHOWCASE_SCRIPT = "showcase_db.py"
OUTPUT_FILENAME = "library_erd"

def ensure_db_exists():
    """ Проверяет наличие файла БД и создает его, если он отсутствует """
    if not os.path.exists(DB_FILE):
        print(f"Файл '{DB_FILE}' не найден. Запускаю '{SHOWCASE_SCRIPT}' для его создания...")
        try:
            subprocess.run(["python3", SHOWCASE_SCRIPT], check=True)
            print("База данных успешно создана.")
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"Ошибка при создании базы данных: {e}")
            return False
    return True

def get_schema_details(conn):
    """
    Извлекает информацию о таблицах, колонках и внешних ключах из БД.
    """
    cursor = conn.cursor()

    # Получаем список таблиц
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tables = [row[0] for row in cursor.fetchall()]

    schema = {'tables': {}, 'relations': []}

    for table_name in tables:
        # Получаем информацию о колонках
        cursor.execute(f"PRAGMA table_info('{table_name}');")
        columns = []
        for row in cursor.fetchall():
            # cid, name, type, notnull, dflt_value, pk
            columns.append({'name': row[1], 'type': row[2], 'pk': bool(row[5])})
        schema['tables'][table_name] = columns

        # Получаем информацию о внешних ключах
        cursor.execute(f"PRAGMA foreign_key_list('{table_name}');")
        for row in cursor.fetchall():
            # id, seq, table, from, to, on_update, on_delete, match
            schema['relations'].append({
                'from_table': table_name,
                'from_col': row[3],
                'to_table': row[2],
                'to_col': row[4]
            })

    return schema

def generate_diagram(schema, output_filename):
    """
    Генерирует ERD-диаграмму на основе извлеченной схемы.
    """
    dot = graphviz.Digraph('ERD', comment='Library DB Schema')
    dot.attr('graph',
             rankdir='LR',  # Слева направо
             splines='ortho',
             nodesep='1.0',
             ranksep='1.5',
             fontname='Arial')
    dot.attr('node', shape='plain', fontname='Arial')
    dot.attr('edge', fontname='Arial', fontsize='10')

    # Создаем узлы для каждой таблицы
    for table_name, columns in schema['tables'].items():
        # Собираем HTML-подобную метку для таблицы
        rows = [f'<tr><td bgcolor="#336699" colspan="3"><font color="white"><b>{table_name}</b></font></td></tr>']
        for col in columns:
            pk_symbol = '🔑' if col['pk'] else ''
            rows.append(f'<tr><td align="left">{pk_symbol} {col["name"]}</td><td align="left">{col["type"]}</td></tr>')

        label = f'<<table border="1" cellborder="1" cellspacing="0">{"".join(rows)}</table>>'
        dot.node(table_name, label=label)

    # Создаем связи между таблицами
    for relation in schema['relations']:
        dot.edge(
            relation['from_table'],
            relation['to_table'],
            label=f"{relation['from_col']} → {relation['to_col']}",
            tailport='e', # хвост от правого края
            headport='w' # голова к левому краю
        )

    # Рендерим и сохраняем диаграмму
    try:
        dot.render(output_filename, format='png', view=False, cleanup=True)
        print(f"Диаграмма успешно сохранена в файл: {output_filename}.png")
    except Exception as e:
        print(f"Ошибка при рендеринге диаграммы: {e}")
        print("Убедитесь, что Graphviz установлен в вашей системе (не только Python-библиотека).")

def main():
    """ Основная функция """
    if not ensure_db_exists():
        return

    conn = sqlite3.connect(DB_FILE)
    try:
        schema = get_schema_details(conn)
        generate_diagram(schema, OUTPUT_FILENAME)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
