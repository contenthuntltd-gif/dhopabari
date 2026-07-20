import React from 'react';
import { ViewStyle } from 'react-native';
import Svg, { Path, Rect, Circle } from 'react-native-svg';

interface LogoProps {
  width?: number;
  height?: number;
  style?: ViewStyle;
}

export default function Logo({ width = 80, height = 80, style }: LogoProps) {
  return (
    <Svg width={width} height={height} viewBox="0 0 100 100" fill="none" style={style}>
      {/* Rounded arc at the bottom (Teal) */}
      <Path d="M10 78 Q50 71 90 78" stroke="#00d2c4" strokeWidth={3.2} fill="none" strokeLinecap="round" />
      
      {/* Chimney (Dark Blue) */}
      <Rect x={66} y={23} width={8} height={15} fill="#025bf3" rx={1} />
      
      {/* House contour (Dark Blue) */}
      <Path d="M18 38 L50 12 L82 38 L74 38 V72 H26 V38 Z" fill="#025bf3" />
      
      {/* Washing Machine Outer Body (White) */}
      <Rect x={34} y={39} width={32} height={32} rx={4.5} fill="#ffffff" />
      {/* Control Panel Drawer (Blue) */}
      <Rect x={38} y={43} width={12} height={2} rx={1} fill="#025bf3" />
      {/* Control Dial (Teal) */}
      <Circle cx={58} cy={44} r={1.5} fill="#00d2c4" />
      {/* Door Rim (Blue) */}
      <Circle cx={50} cy={57} r={10.5} stroke="#025bf3" strokeWidth={2.5} fill="none" />
      {/* Door Glass Inner (Light Blue) */}
      <Circle cx={50} cy={57} r={8} fill="#e1f1ff" />
      {/* Water wave inside (Teal) */}
      <Path d="M42 57 C 45 62, 55 52, 58 57 A 8 8 0 0 1 42 57 Z" fill="#00d2c4" />
      
      {/* Folded clothes stacked on the left */}
      {/* Cloth 3 (bottom - Blue) */}
      <Path d="M13 63 H27 C29 63, 29 66, 27 66 H13 C11 66, 11 63, 13 63 Z" fill="#025bf3" />
      {/* Cloth 2 (middle - Teal) */}
      <Path d="M13 59 H27 C29 59, 29 62, 27 62 H13 C11 62, 11 59, 13 59 Z" fill="#00d2c4" />
      {/* Cloth 1 (top - Blue) */}
      <Path d="M13 55 H27 C29 55, 29 58, 27 58 H13 C11 58, 11 55, 13 55 Z" fill="#025bf3" />
      
      {/* Clean sparkles on the right (Teal) */}
      {/* Sparkle 1 */}
      <Path d="M82 41 Q82 45 86 45 Q82 45 82 49 Q82 45 78 45 Q82 45 82 41 Z" fill="#00d2c4" />
      {/* Sparkle 2 */}
      <Path d="M88 51 Q88 54 91 54 Q88 54 88 57 Q88 54 85 54 Q88 54 88 51 Z" fill="#00d2c4" />
      {/* Sparkle 3 */}
      <Path d="M78 53 Q78 55 80 55 Q78 55 78 57 Q78 55 76 55 Q78 55 78 53 Z" fill="#00d2c4" />
    </Svg>
  );
}
