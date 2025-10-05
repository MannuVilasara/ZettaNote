import React, { useState } from 'react';
import {
  Box,
  Container,
  TextField,
  Typography,
  Paper,
  IconButton,
  InputAdornment,
} from '@mui/material';
import { Visibility, VisibilityOff } from '@mui/icons-material';
import { LoadingButton } from '@mui/lab';
import { useNavigate } from 'react-router-dom';
import Navbar from '../components/ui/Navbar';

import { API_URL } from '../config';

export default function Signup() {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setErrors('');
    let data;

    try {
      const res = await fetch(API_URL + '/api/auth/signup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name, email, password, confirmPassword }),
      });

      data = await res.json();
      if (res.status !== 200) {
        setErrors(data.Error);
      } else {
        localStorage.setItem('token', data.token);
        navigate('/home');
      }
    } catch (err) {
      setErrors(data.Error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      <Navbar />
      <Container maxWidth="sm" sx={{ pt: 12 }}>
        <Paper elevation={4} sx={{ p: 4, borderRadius: 3 }}>
          <Typography variant="h4" align="center" gutterBottom>
            Sign Up
          </Typography>

          <Box
            component="form"
            onSubmit={handleSubmit}
            sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}
          >
            {errors && (
              <Typography color="error" variant="body2" align="center">
                {errors}
              </Typography>
            )}

            <TextField
              label="Name"
              type="text"
              variant="outlined"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              fullWidth
            />

            <TextField
              label="Email"
              type="email"
              variant="outlined"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              fullWidth
            />

            <TextField
              label="Password"
              type={showPassword ? 'text' : 'password'}
              variant="outlined"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              fullWidth
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setShowPassword(!showPassword)}
                      edge="end"
                      aria-label="toggle password visibility"
                    >
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <TextField
              label="Confirm Password"
              type={showConfirmPassword ? 'text' : 'password'}
              variant="outlined"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              fullWidth
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      edge="end"
                      aria-label="toggle confirm password visibility"
                    >
                      {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <LoadingButton
              type="submit"
              variant="contained"
              color="primary"
              size="large"
              loading={loading}
            >
              Sign Up
            </LoadingButton>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}
