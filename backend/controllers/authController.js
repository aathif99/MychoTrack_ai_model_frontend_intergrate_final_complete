const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const path = require('path');
const fs = require('fs');
const db = require('../config/db');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : 587,
    secure: process.env.SMTP_PORT === '465',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    }
});

const validatePassword = (password) => {
    if (!password || password.length < 8) {
        return 'Password must be at least 8 characters long';
    }
    if (!/[A-Z]/.test(password)) {
        return 'Password must contain at least 1 uppercase letter (A-Z)';
    }
    if (!/[a-z]/.test(password)) {
        return 'Password must contain at least 1 lowercase letter (a-z)';
    }
    if (!/[0-9]/.test(password)) {
        return 'Password must contain at least 1 number (0-9)';
    }
    if (!/[^a-zA-Z0-9\s]/.test(password)) {
        return 'Password must contain at least 1 special character (@, #, $, %, etc.)';
    }
    if (/\s/.test(password)) {
        return 'Password cannot contain spaces';
    }
    return null;
};

exports.register = async (req, res) => {
    const { username, email, password } = req.body;

    // Basic validation
    if (!username || !email || !password) {
        return res.status(400).json({ error: 'Please provide all required fields' });
    }

    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ error: 'Please enter a valid email address' });
    }

    const passwordError = validatePassword(password);
    if (passwordError) {
        return res.status(400).json({ error: passwordError });
    }

    try {
        // Check if email exists
        const [existingUser] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (existingUser.length > 0) {
            return res.status(400).json({ error: 'Email already exists' });
        }

        // Hash password using SHA-256
        const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');

        // Insert user
        const [result] = await db.execute(
            'INSERT INTO users (user_name, email, password) VALUES (?, ?, ?)',
            [username, email, hashedPassword]
        );

        res.status(201).json({ message: 'User registered successfully', userId: result.insertId });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Server error during registration' });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Please provide email and password' });
    }

    try {
        // Check for user
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(400).json({ error: 'Invalid credentials' });
        }

        const user = users[0];

        // Validate password using SHA-256
        const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');
        if (hashedPassword !== user.password) {
            return res.status(400).json({ error: 'Invalid credentials' });
        }

        // Create token
        const payload = {
            user: {
                id: user.user_id,
                username: user.user_name
            }
        };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN },
            (err, token) => {
                if (err) throw err;
                res.json({
                    message: 'Login successful',
                    token,
                    user: {
                        id: user.user_id,
                        username: user.user_name,
                        email: user.email,
                        profile_picture: user.profile_picture || null
                    }
                });
            }
        );
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Server error during login' });
    }
};

exports.logout = (req, res) => {
    // JWT is stateless, so logout is typically handled client-side by deleting the token.
    // Here we just return a success response.
    res.json({ message: 'Logged out successfully. Please remove token on client.' });
};

exports.getProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const [users] = await db.execute(
            'SELECT user_id, user_name, email, profile_picture FROM users WHERE user_id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const user = users[0];
        res.json({
            success: true,
            user: {
                id: user.user_id,
                username: user.user_name,
                email: user.email,
                profile_picture: user.profile_picture || null
            }
        });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ error: 'Server error retrieving profile' });
    }
};

exports.uploadProfilePicture = async (req, res) => {
    try {
        const userId = req.user.id;
        if (!req.file) {
            return res.status(400).json({ error: 'No image file uploaded' });
        }

        // Check and delete previous profile picture if exists
        const [users] = await db.execute(
            'SELECT profile_picture FROM users WHERE user_id = ?',
            [userId]
        );

        if (users.length > 0 && users[0].profile_picture) {
            const oldRelativePath = users[0].profile_picture;
            const oldFullPath = path.join(__dirname, '..', oldRelativePath);
            if (fs.existsSync(oldFullPath)) {
                try {
                    fs.unlinkSync(oldFullPath);
                } catch (err) {
                    console.warn('Failed to delete old profile picture:', err.message);
                }
            }
        }

        const profilePictureUrl = `/profile_picture/${req.file.filename}`;
        await db.execute(
            'UPDATE users SET profile_picture = ? WHERE user_id = ?',
            [profilePictureUrl, userId]
        );

        res.json({
            success: true,
            message: 'Profile picture updated successfully',
            profile_picture: profilePictureUrl
        });
    } catch (error) {
        console.error('Upload profile picture error:', error);
        res.status(500).json({ error: 'Server error uploading profile picture' });
    }
};

exports.deleteProfilePicture = async (req, res) => {
    try {
        const userId = req.user.id;
        const [users] = await db.execute(
            'SELECT profile_picture FROM users WHERE user_id = ?',
            [userId]
        );

        if (users.length > 0 && users[0].profile_picture) {
            const oldRelativePath = users[0].profile_picture;
            const oldFullPath = path.join(__dirname, '..', oldRelativePath);
            if (fs.existsSync(oldFullPath)) {
                try {
                    fs.unlinkSync(oldFullPath);
                } catch (err) {
                    console.warn('Failed to delete profile picture file:', err.message);
                }
            }
        }

        await db.execute(
            'UPDATE users SET profile_picture = NULL WHERE user_id = ?',
            [userId]
        );

        res.json({
            success: true,
            message: 'Profile picture removed successfully'
        });
    } catch (error) {
        console.error('Delete profile picture error:', error);
        res.status(500).json({ error: 'Server error removing profile picture' });
    }
};

exports.forgotPassword = async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    try {
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(404).json({ error: 'User with this email does not exist' });
        }

        const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
        const expires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

        await db.execute(
            'UPDATE users SET reset_code = ?, reset_code_expires = ? WHERE email = ?',
            [resetCode, expires, email]
        );

        console.log(`[AUTH] Generated OTP reset code for ${email}: ${resetCode}`);

        const senderAddress = process.env.SMTP_USER || 'noreply@mycotrack.com';
        const mailOptions = {
            from: `"MycoTrack Support" <${senderAddress}>`,
            to: email,
            subject: 'MycoTrack - Password Reset OTP Code',
            text: `Your MycoTrack password reset code is: ${resetCode}\nThis code will expire in 15 minutes.`,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                    <h2 style="color: #8B6456; text-align: center;">MycoTrack Security</h2>
                    <p>Hello,</p>
                    <p>You requested a password reset for your MycoTrack account. Use the 6-digit OTP code below to verify your identity:</p>
                    <div style="background-color: #f7ecd6; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #8B6456;">${resetCode}</span>
                    </div>
                    <p style="color: #666; font-size: 14px;">This OTP code will expire in <strong>15 minutes</strong>. If you did not request this, please ignore this email.</p>
                </div>
            `
        };

        try {
            const info = await transporter.sendMail(mailOptions);
            console.log('OTP Email successfully sent: %s', info.messageId);
        } catch (mailErr) {
            console.warn('Notice: Could not dispatch live email (check SMTP credentials in .env). OTP code is:', resetCode);
        }

        res.json({ message: 'Reset code sent to email', success: true });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ error: 'Server error' });
    }
};

exports.checkResetEmail = async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email is required' });
    try {
        const [users] = await db.execute('SELECT user_id, user_name, email FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(404).json({ success: false, message: 'Email address does not exist' });
        }
        res.json({
            success: true,
            user: {
                id: users[0].user_id,
                username: users[0].user_name,
                email: users[0].email
            }
        });
    } catch (error) {
        console.error('Check reset email error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.resetPasswordDirect = async (req, res) => {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ success: false, message: 'Email and new password required' });
    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ success: false, message: passwordError });
    try {
        const hashedPassword = crypto.createHash('sha256').update(newPassword).digest('hex');
        const [result] = await db.execute('UPDATE users SET password = ? WHERE email = ?', [hashedPassword, email]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        res.json({ success: true, message: 'Password updated successfully' });
    } catch (error) {
        console.error('Reset password direct error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};

exports.verifyResetCode = async (req, res) => {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ error: 'Email and code are required' });

    try {
        const [users] = await db.execute(
            'SELECT * FROM users WHERE email = ? AND reset_code = ? AND reset_code_expires > NOW()',
            [email, code]
        );

        if (users.length === 0) {
            return res.status(400).json({ error: 'Invalid OTP' });
        }

        res.json({ message: 'Code verified successfully' });
    } catch (error) {
        console.error('Verify reset code error:', error);
        res.status(500).json({ error: 'Server error' });
    }
};

exports.resetPassword = async (req, res) => {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ error: 'Email and new password are required' });

    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ error: passwordError });

    try {
        const hashedPassword = crypto.createHash('sha256').update(newPassword).digest('hex');

        const [result] = await db.execute(
            'UPDATE users SET password = ?, reset_code = NULL, reset_code_expires = NULL WHERE email = ?',
            [hashedPassword, email]
        );

        if (result.affectedRows === 0) {
            return res.status(400).json({ error: 'Failed to reset password' });
        }

        res.json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ error: 'Server error' });
    }
};
