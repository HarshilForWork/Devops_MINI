-- Database initialization script
-- This will run automatically when MySQL container starts for the first time

USE book_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create books table
CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100) NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create indexes for better performance
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_book_user_id ON books(user_id);

-- Insert sample data (optional - for testing)
-- Password is 'test123' hashed with werkzeug
INSERT INTO users (name, email, password) VALUES 
('Test User', 'test@example.com', 'scrypt:32768:8:1$hVZ9YqW2vF8N3gKx$8f7a5e6c9b4d3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8f');

INSERT INTO books (title, author, user_id) VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', 1),
('To Kill a Mockingbird', 'Harper Lee', 1),
('1984', 'George Orwell', 1),
('Pride and Prejudice', 'Jane Austen', 1),
('The Catcher in the Rye', 'J.D. Salinger', 1);

-- Show created tables
SHOW TABLES;
