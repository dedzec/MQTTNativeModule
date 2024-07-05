import React from 'react';
import { TouchableOpacity, ActivityIndicator, Text } from 'react-native';

function TextButton(props) {
  const {
    contentContainerStyle,
    loading,
    disabled,
    label,
    labelStyle,
    iconStart,
    iconEnd,
    onPress,
  } = props;

  return (
    <TouchableOpacity
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#fff',
        ...contentContainerStyle,
      }}
      disabled={disabled}
      onPress={onPress}
    >
      {loading ? (
        <ActivityIndicator color={'#FFF'} animating={true} />
      ) : (
        <>
          {iconStart}
          <Text
            style={{
              color: '#fff',
              fontFamily: 'Roboto-Bold',
              fontSize: 16,
              lineHeight: 22,
              ...labelStyle,
            }}
          >
            {label}
          </Text>
          {iconEnd}
        </>
      )}
    </TouchableOpacity>
  );
}

export default TextButton;
