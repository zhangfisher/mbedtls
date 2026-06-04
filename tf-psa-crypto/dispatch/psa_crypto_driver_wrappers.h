/*
 *  Function signatures for functionality that can be provided by
 *  cryptographic accelerators.
 */
/*  Copyright The Mbed TLS Contributors
 *  SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later
 */

#ifndef TF_PSA_CRYPTO_PSA_CRYPTO_DRIVER_WRAPPERS_H
#define TF_PSA_CRYPTO_PSA_CRYPTO_DRIVER_WRAPPERS_H

#include "psa/crypto.h"
#include "psa/crypto_driver_common.h"

// 包含 no_static 版本的头文件
#include "psa_crypto_driver_wrappers_no_static.h"

// 哈希操作
psa_status_t psa_driver_wrapper_hash_abort(psa_hash_operation_t *operation);
psa_status_t psa_driver_wrapper_hash_setup(psa_hash_operation_t *operation, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_hash_update(psa_hash_operation_t *operation, const uint8_t *input, size_t input_length);
psa_status_t psa_driver_wrapper_hash_finish(psa_hash_operation_t *operation, uint8_t *hash, size_t hash_size, size_t *hash_length);
psa_status_t psa_driver_wrapper_hash_compute(psa_algorithm_t alg, const uint8_t *input, size_t input_length, uint8_t *hash, size_t hash_size, size_t *hash_length);
psa_status_t psa_driver_wrapper_hash_clone(const psa_hash_operation_t *source_operation, psa_hash_operation_t *target_operation);

// XOF (Extendable-Output Functions) 操作 - 使用 psa_xof_operation_t
psa_status_t psa_driver_wrapper_xof_abort(psa_xof_operation_t *operation);
psa_status_t psa_driver_wrapper_xof_setup(psa_xof_operation_t *operation, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_xof_update(psa_xof_operation_t *operation, const uint8_t *input, size_t input_length);
psa_status_t psa_driver_wrapper_xof_output(psa_xof_operation_t *operation, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_xof_set_context(psa_xof_operation_t *operation, const uint8_t *context, size_t context_length);

// MAC 操作
psa_status_t psa_driver_wrapper_mac_abort(psa_mac_operation_t *operation);
psa_status_t psa_driver_wrapper_mac_sign_setup(psa_mac_operation_t *operation, const psa_key_attributes_t *attributes, uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_mac_verify_setup(psa_mac_operation_t *operation, const psa_key_attributes_t *attributes, uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_mac_update(psa_mac_operation_t *operation, const uint8_t *input, size_t input_length);
psa_status_t psa_driver_wrapper_mac_sign_finish(psa_mac_operation_t *operation, uint8_t *signature, size_t signature_size, size_t *signature_length);
psa_status_t psa_driver_wrapper_mac_verify_finish(psa_mac_operation_t *operation, const uint8_t *signature, size_t signature_length);
psa_status_t psa_driver_wrapper_mac_compute(psa_algorithm_t alg, const uint8_t *key_buffer, size_t key_buffer_size, const uint8_t *input, size_t input_length, uint8_t *mac, size_t mac_size, size_t *mac_length);

// Cipher 操作
psa_status_t psa_driver_wrapper_cipher_encrypt_setup(psa_cipher_operation_t *operation, const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_cipher_decrypt_setup(psa_cipher_operation_t *operation, const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_cipher_set_iv(psa_cipher_operation_t *operation, const uint8_t *iv, size_t iv_length);
psa_status_t psa_driver_wrapper_cipher_update(psa_cipher_operation_t *operation, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_cipher_finish(psa_cipher_operation_t *operation, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_cipher_abort(psa_cipher_operation_t *operation);
psa_status_t psa_driver_wrapper_cipher_encrypt(const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_cipher_decrypt(const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);

// AEAD 操作
psa_status_t psa_driver_wrapper_aead_encrypt(const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *nonce, size_t nonce_length, const uint8_t *additional_data, size_t additional_data_length, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_aead_decrypt(const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *nonce, size_t nonce_length, const uint8_t *additional_data, size_t additional_data_length, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_aead_encrypt_setup(psa_aead_operation_t *operation, const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_aead_decrypt_setup(psa_aead_operation_t *operation, const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg);
psa_status_t psa_driver_wrapper_aead_set_nonce(psa_aead_operation_t *operation, const uint8_t *nonce, size_t nonce_length);
psa_status_t psa_driver_wrapper_aead_set_lengths(psa_aead_operation_t *operation, size_t ad_length, size_t plaintext_length);
psa_status_t psa_driver_wrapper_aead_update_ad(psa_aead_operation_t *operation, const uint8_t *input, size_t input_length);
psa_status_t psa_driver_wrapper_aead_update(psa_aead_operation_t *operation, const uint8_t *input, size_t input_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_aead_finish(psa_aead_operation_t *operation, uint8_t *tag, size_t tag_size, size_t *tag_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_aead_verify(psa_aead_operation_t *operation, const uint8_t *tag, size_t tag_length, uint8_t *output, size_t output_size, size_t *output_length);
psa_status_t psa_driver_wrapper_aead_abort(psa_aead_operation_t *operation);

// 密钥操作
psa_status_t psa_driver_wrapper_export_key(const psa_key_attributes_t *attributes, const uint8_t *key_buffer, size_t key_buffer_size, uint8_t *data, size_t data_size, size_t *data_length);
psa_status_t psa_driver_wrapper_import_key(const psa_key_attributes_t *attributes, const uint8_t *data, size_t data_length, uint8_t *key_buffer, size_t key_buffer_size, size_t *key_buffer_length, size_t *key_bits);
psa_status_t psa_driver_wrapper_copy_key(const psa_key_attributes_t *attributes, const uint8_t *source_key, size_t source_key_length, uint8_t *target_key_buffer, size_t target_key_buffer_size, size_t *target_key_length);
psa_status_t psa_driver_wrapper_get_key_buffer_size_from_key_data(const psa_key_attributes_t *attributes, const uint8_t *data, size_t data_length, size_t *key_buffer_size);

// 签名和验证操作
psa_status_t psa_driver_wrapper_sign_message(const psa_key_attributes_t *attributes, uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *input, size_t input_length, uint8_t *signature, size_t signature_size, size_t *signature_length);
psa_status_t psa_driver_wrapper_verify_message(const psa_key_attributes_t *attributes, uint8_t *key_buffer, size_t key_buffer_size, psa_algorithm_t alg, const uint8_t *input, size_t input_length, const uint8_t *signature, size_t signature_length);

#endif /* TF_PSA_CRYPTO_PSA_CRYPTO_DRIVER_WRAPPERS_H */
