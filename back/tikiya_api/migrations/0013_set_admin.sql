-- Passe le compte rayanbenhabiles9@gmail.com en administrateur
UPDATE users
SET role = 'admin'
WHERE email = 'rayanbenhabiles9@gmail.com';
