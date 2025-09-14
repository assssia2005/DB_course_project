import sqlite3
import os
from datetime import date, timedelta

DB_FILE = "library.db"
SCHEMA_FILE = "library_schema_sqlite.sql"

def create_connection(db_file):
    """ Создает соединение с базой данных SQLite """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(f"SQLite DB: версия {sqlite3.sqlite_version}")
        # Включаем поддержку внешних ключей
        conn.execute("PRAGMA foreign_keys = ON;")
    except sqlite3.Error as e:
        print(e)
    return conn

def execute_sql_script(conn, script_file):
    """ Выполняет SQL-скрипт из файла """
    try:
        with open(script_file, 'r', encoding='utf-8') as f:
            sql_script = f.read()
        cursor = conn.cursor()
        cursor.executescript(sql_script)
        conn.commit()
        print(f"Скрипт '{script_file}' успешно выполнен.")
    except sqlite3.Error as e:
        print(f"Ошибка при выполнении скрипта: {e}")

def add_member(conn, first_name, last_name, email, membership_expiry_date):
    """ Добавляет нового читателя в базу данных """
    sql = '''INSERT INTO Members(FirstName, LastName, Email, MembershipExpiryDate)
             VALUES(?,?,?,?)'''
    try:
        cursor = conn.cursor()
        cursor.execute(sql, (first_name, last_name, email, membership_expiry_date))
        conn.commit()
        print(f"Добавлен новый читатель: {first_name} {last_name}")
        return cursor.lastrowid
    except sqlite3.IntegrityError as e:
        print(f"Ошибка: Не удалось добавить читателя. Возможно, email '{email}' уже существует. {e}")
        return None


def find_available_copy(conn, book_title):
    """ Находит доступный экземпляр книги по её названию """
    sql = """
    SELECT bc.CopyID
    FROM BookCopies bc
    JOIN Books b ON bc.BookID = b.BookID
    WHERE b.Title = ? AND bc.Status = 'available'
    LIMIT 1;
    """
    cursor = conn.cursor()
    cursor.execute(sql, (book_title,))
    result = cursor.fetchone()
    if result:
        print(f"Найден доступный экземпляр книги '{book_title}' с ID: {result[0]}")
        return result[0]
    else:
        print(f"Книга '{book_title}' не найдена или все экземпляры на руках.")
        return None

def loan_copy_to_member(conn, copy_id, member_id):
    """ Выдает экземпляр книги читателю """
    issue_date = date.today()
    due_date = issue_date + timedelta(days=14) # Книга выдается на 2 недели

    try:
        cursor = conn.cursor()

        # 1. Обновляем статус копии книги
        update_sql = "UPDATE BookCopies SET Status = 'on_loan' WHERE CopyID = ?"
        cursor.execute(update_sql, (copy_id,))

        # 2. Создаем запись о выдаче
        insert_sql = """
        INSERT INTO Loans(CopyID, MemberID, IssueDate, DueDate)
        VALUES(?, ?, ?, ?)
        """
        cursor.execute(insert_sql, (copy_id, member_id, issue_date.isoformat(), due_date.isoformat()))

        conn.commit()
        print(f"Экземпляр {copy_id} выдан читателю {member_id}. Срок возврата: {due_date.isoformat()}")
        return True
    except sqlite3.Error as e:
        conn.rollback()
        print(f"Ошибка при выдаче книги: {e}")
        return False

def list_active_loans(conn):
    """ Выводит список всех книг, находящихся на руках у читателей """
    sql = """
    SELECT
        m.FirstName || ' ' || m.LastName AS MemberName,
        b.Title,
        l.IssueDate,
        l.DueDate
    FROM Loans l
    JOIN Members m ON l.MemberID = m.MemberID
    JOIN BookCopies bc ON l.CopyID = bc.CopyID
    JOIN Books b ON bc.BookID = b.BookID
    WHERE l.ActualReturnDate IS NULL;
    """
    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()

    print("\n--- СПИСОК АКТИВНЫХ ВЫДАЧ ---")
    if not rows:
        print("Все книги в библиотеке.")
    else:
        for row in rows:
            print(f"Читатель: {row[0]}, Книга: '{row[1]}', Дата выдачи: {row[2]}, Срок возврата: {row[3]}")
    print("-----------------------------\n")


def main():
    """ Основная функция для демонстрации работы с БД """
    # Удаляем старый файл БД, если он существует, для чистоты эксперимента
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)
        print(f"Старый файл '{DB_FILE}' удален.")

    # Создаем соединение и схему
    conn = create_connection(DB_FILE)
    if conn is not None:
        execute_sql_script(conn, SCHEMA_FILE)

        # --- ДЕМОНСТРАЦИОННЫЙ СЦЕНАРИЙ ---

        # 1. Показываем текущий список активных выдач (изначально там одна)
        print("\n*** Шаг 1: Проверяем начальное состояние выдач ***")
        list_active_loans(conn)

        # 2. Добавляем нового читателя
        print("\n*** Шаг 2: Добавляем нового читателя ***")
        new_member_id = add_member(conn, "Алиса", "Селезнёва", "alisa@future.com", "2099-12-31")

        if new_member_id:
            # 3. Ищем доступную книгу
            print("\n*** Шаг 3: Ищем доступную книгу '1984' ***")
            available_copy_id = find_available_copy(conn, "1984")

            # 4. Если книга найдена, выдаем ее новому читателю
            if available_copy_id:
                print("\n*** Шаг 4: Выдаем книгу новому читателю ***")
                loan_copy_to_member(conn, available_copy_id, new_member_id)

        # 5. Снова показываем список активных выдач, чтобы увидеть изменения
        print("\n*** Шаг 5: Проверяем итоговое состояние выдач ***")
        list_active_loans(conn)

        # Закрываем соединение
        conn.close()
        print("Соединение с БД закрыто.")

if __name__ == '__main__':
    main()
