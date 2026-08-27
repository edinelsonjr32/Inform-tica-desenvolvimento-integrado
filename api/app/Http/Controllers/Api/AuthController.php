<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function login(Request $request){
        $credencial = $request->validate(
            [
                'email' => 'required',
                'password' => 'required'
            ]
        );

        if (!Auth::attempt($credencial)){
            return response()->json([
                'message'=> 'Login Inválido', 401
            ]);
        }

        $usuario = Auth::user();
        $token = $usuario->createToken('auth-token')->plainTextToken;

        return response()->json([
            'user' => $usuario,
            'token' => $token
        ]);

    }
}
