import React from 'react';
import { Dimensions, View, Text, TextInput } from 'react-native';

const { height } = Dimensions.get('window');

function FormInput(props) {
  const {
    containerStyle,
    inputContainerStyle,
    label,
    placeholder,
    inputStyle,
    value = '',
    prependComponent,
    appendComponent,
    onChange,
    require,
    secureTextEntry,
    keyboardType = 'default',
    autoCompleteType = 'off',
    autoCapitalize = 'none',
    errorMsg = '',
    maxLength,
  } = props;

  return (
    <View style={{ ...containerStyle }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
        {require ? (
          <Text
            style={{
              color: '#7F7F7F',
              fontFamily: 'Roboto-Regular',
              fontSize: 14,
              lineHeight: 22,
            }}
          >
            {label} *
          </Text>
        ) : (
          <Text
            style={{
              color: '#7F7F7F',
              fontFamily: 'Roboto-Regular',
              fontSize: 14,
              lineHeight: 22,
            }}
          >
            {label}
          </Text>
        )}

        <Text
          style={{
            color: '#FF1717',
            fontFamily: 'Roboto-Regular',
            fontSize: 14,
            lineHeight: 22,
          }}
        >
          {errorMsg}
        </Text>
      </View>

      <View
        style={{
          flexDirection: 'row',
          height: height > 800 ? 55 : 45,
          paddingHorizontal: 24,
          marginTop: height > 800 ? 8 : 0,
          borderRadius: 13,
          backgroundColor: '#F5F5F8',
          ...inputContainerStyle,
        }}
      >
        {prependComponent}
        <TextInput
          style={{ flex: 1, ...inputStyle }}
          value={value}
          placeholder={placeholder}
          placeholderTextColor='#898B9A'
          secureTextEntry={secureTextEntry}
          keyboardType={keyboardType}
          autoCompleteType={autoCompleteType}
          autoCapitalize={autoCapitalize}
          maxLength={maxLength}
          onChangeText={(text) => onChange(text)}
        />
        {appendComponent}
      </View>
    </View>
  );
}

export default FormInput;
